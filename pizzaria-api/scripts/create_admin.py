import asyncio
import getpass
import sys

from sqlalchemy import select

from app.core.database import session_factory
from app.core.security import hash_password
from app.models.user import User


async def create_admin(name: str, email: str, password: str) -> None:
    normalized_email = email.strip().lower()
    async with session_factory() as session:
        user = await session.scalar(select(User).where(User.email == normalized_email))
        if user is None:
            user = User(name=name.strip(), email=normalized_email, password_hash=hash_password(password), role="ADMIN")
            session.add(user)
        else:
            user.name = name.strip()
            user.password_hash = hash_password(password)
            user.role = "ADMIN"
            user.is_active = True
            user.deleted_at = None
        await session.commit()
    print(f"Administrador configurado: {normalized_email}")


if __name__ == "__main__":
    if len(sys.argv) not in {3, 4}:
        raise SystemExit("Uso: python scripts/create_admin.py 'Nome' email [senha]")
    password = sys.argv[3] if len(sys.argv) == 4 else getpass.getpass("Senha do administrador: ")
    if len(password) < 8:
        raise SystemExit("A senha deve ter pelo menos 8 caracteres.")
    asyncio.run(create_admin(sys.argv[1], sys.argv[2], password))
