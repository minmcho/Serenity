"""
VitalPath AI - ChromaDB Vector Store for Semantic Memory (RAG)
"""
import chromadb
from chromadb.config import Settings
from typing import List, Dict, Optional
from datetime import datetime
import structlog

from app.config import settings

logger = structlog.get_logger()


class ChromaDBService:
    """ChromaDB vector store for user context and semantic memory."""
    
    _client: Optional[chromadb.Client] = None
    _collection: Optional[chromadb.Collection] = None
    
    @classmethod
    def get_client(cls) -> chromadb.Client:
        """Get or create ChromaDB client."""
        if cls._client is None:
            cls._client = chromadb.HttpClient(
                host=settings.chromadb_url.replace("http://", "").split(":")[0],
                port=int(settings.chromadb_url.split(":")[-1].split("/")[0]) if ":" in settings.chromadb_url else 8000
            )
            logger.info("chromadb_client_initialized")
        return cls._client
    
    @classmethod
    def get_collection(cls) -> chromadb.Collection:
        """Get or create the user wellness context collection."""
        if cls._collection is None:
            client = cls.get_client()
            cls._collection = client.get_or_create_collection(
                name="user_wellness_context",
                metadata={"hnsw:space": "cosine"}
            )
            logger.info("chromadb_collection_ready")
        return cls._collection
    
    @classmethod
    async def store_user_context(
        cls,
        user_id: str,
        context_text: str,
        context_type: str = "preference",
        metadata: Optional[Dict] = None
    ) -> bool:
        """
        Store user context in vector database.
        
        Args:
            user_id: User identifier
            context_text: Text content to embed
            context_type: Type of context (preference, goal, habit, etc.)
            metadata: Additional metadata
        
        Returns:
            True if successful
        """
        try:
            collection = cls.get_collection()
            
            # Generate unique ID
            doc_id = f"{user_id}_{context_type}_{datetime.utcnow().timestamp()}"
            
            # Prepare metadata
            doc_metadata = {
                "user_id": user_id,
                "context_type": context_type,
                "created_at": datetime.utcnow().isoformat(),
                **(metadata or {})
            }
            
            # Add to collection
            collection.add(
                documents=[context_text],
                metadatas=[doc_metadata],
                ids=[doc_id]
            )
            
            logger.info(
                "user_context_stored",
                user_id=user_id,
                type=context_type,
                length=len(context_text)
            )
            return True
            
        except Exception as e:
            logger.error("store_context_failed", user_id=user_id, error=str(e))
            return False
    
    @classmethod
    async def retrieve_user_context(
        cls,
        user_id: str,
        query_text: str,
        limit: int = 5
    ) -> List[Dict]:
        """
        Retrieve relevant user context for RAG.
        
        Args:
            user_id: User identifier
            query_text: Query text for similarity search
            limit: Maximum number of results
        
        Returns:
            List of relevant context documents
        """
        try:
            collection = cls.get_collection()
            
            results = collection.query(
                query_texts=[query_text],
                n_results=limit,
                where={"user_id": user_id}
            )
            
            contexts = []
            if results["documents"] and results["documents"][0]:
                for i, doc in enumerate(results["documents"][0]):
                    contexts.append({
                        "content": doc,
                        "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                        "distance": results["distances"][0][i] if results["distances"] else 0.0
                    })
            
            logger.info(
                "context_retrieved",
                user_id=user_id,
                count=len(contexts)
            )
            return contexts
            
        except Exception as e:
            logger.error("retrieve_context_failed", user_id=user_id, error=str(e))
            return []
    
    @classmethod
    async def get_user_preferences(cls, user_id: str) -> List[str]:
        """Get all stored preferences for a user."""
        try:
            contexts = await cls.retrieve_user_context(
                user_id=user_id,
                query_text="preferences dietary restrictions likes dislikes",
                limit=20
            )
            
            preferences = [
                ctx["content"] 
                for ctx in contexts 
                if ctx["metadata"].get("context_type") == "preference"
            ]
            
            return preferences
            
        except Exception as e:
            logger.error("get_preferences_failed", user_id=user_id, error=str(e))
            return []
    
    @classmethod
    async def get_user_goals(cls, user_id: str) -> List[str]:
        """Get all stored goals for a user."""
        try:
            contexts = await cls.retrieve_user_context(
                user_id=user_id,
                query_text="goals objectives targets aims",
                limit=10
            )
            
            goals = [
                ctx["content"]
                for ctx in contexts
                if ctx["metadata"].get("context_type") == "goal"
            ]
            
            return goals
            
        except Exception as e:
            logger.error("get_goals_failed", user_id=user_id, error=str(e))
            return []
    
    @classmethod
    async def delete_user_data(cls, user_id: str) -> bool:
        """Delete all data for a user (GDPR compliance)."""
        try:
            collection = cls.get_collection()
            collection.delete(where={"user_id": user_id})
            
            logger.info("user_data_deleted", user_id=user_id)
            return True
            
        except Exception as e:
            logger.error("delete_user_data_failed", user_id=user_id, error=str(e))
            return False
    
    @classmethod
    async def build_context_for_chat(
        cls,
        user_id: str,
        current_message: str
    ) -> str:
        """
        Build contextual prompt for AI chat.
        
        Retrieves relevant user history and formats it for the AI.
        
        Args:
            user_id: User identifier
            current_message: Current user message
        
        Returns:
            Formatted context string
        """
        contexts = await cls.retrieve_user_context(
            user_id=user_id,
            query_text=current_message,
            limit=5
        )
        
        if not contexts:
            return ""
        
        context_parts = []
        for ctx in contexts:
            ctx_type = ctx["metadata"].get("context_type", "info")
            content = ctx["content"]
            context_parts.append(f"- [{ctx_type.upper()}] {content}")
        
        formatted_context = "\n".join(context_parts)
        
        logger.info(
            "chat_context_built",
            user_id=user_id,
            context_lines=len(context_parts)
        )
        
        return f"User Context:\n{formatted_context}\n"


# Convenience functions
async def store_context(user_id: str, text: str, context_type: str = "preference") -> bool:
    return await ChromaDBService.store_user_context(user_id, text, context_type)


async def retrieve_context(user_id: str, query: str, limit: int = 5) -> List[Dict]:
    return await ChromaDBService.retrieve_user_context(user_id, query, limit)


async def build_chat_context(user_id: str, message: str) -> str:
    return await ChromaDBService.build_context_for_chat(user_id, message)
