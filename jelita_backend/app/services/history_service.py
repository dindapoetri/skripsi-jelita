from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional

from app.models.history import HistoryScan
from app.schemas.history_schema import HistoryScanCreate


async def create_history_scan(
    db: AsyncSession,
    user_id: int,
    data: HistoryScanCreate,
) -> HistoryScan:
    scan = HistoryScan(
        user_id=user_id,
        skin_type=data.skin_type,
        cnn_confidence=data.cnn_confidence,
        concerns=data.concerns,
        image_url=data.image_url,
        recommendations_snapshot=data.recommendations_snapshot,
    )
    db.add(scan)
    await db.flush()
    await db.refresh(scan)
    return scan


async def get_user_history(
    db: AsyncSession,
    user_id: int,
    limit: int = 20,
    offset: int = 0,
) -> List[HistoryScan]:
    result = await db.execute(
        select(HistoryScan)
        .where(HistoryScan.user_id == user_id)
        .order_by(desc(HistoryScan.created_at))
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


async def get_history_by_id(
    db: AsyncSession,
    scan_id: int,
    user_id: int,
) -> Optional[HistoryScan]:
    result = await db.execute(
        select(HistoryScan).where(
            HistoryScan.id == scan_id,
            HistoryScan.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def delete_history_scan(
    db: AsyncSession,
    scan_id: int,
    user_id: int,
) -> bool:
    scan = await get_history_by_id(db, scan_id, user_id)
    if not scan:
        return False
    await db.delete(scan)
    return True
