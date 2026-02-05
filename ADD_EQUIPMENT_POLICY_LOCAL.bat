@echo off
echo Dang them/chinh sua chinh sach Cap phat thiet bi...

cd backend

REM Set DATABASE_URL for local (adjust if needed)
set DATABASE_URL=postgresql://postgres:postgres@localhost:5432/asset_rmg_db

echo Generating Prisma Client...
call npx prisma generate

echo Running policy script...
call npm run add-equipment-policy

echo.
echo Hoan tat! Chinh sach Cap phat thiet bi da duoc them/chinh sua.
echo Truy cap: http://localhost:5173/policies de xem.

pause
