@echo off
echo Dang them/chinh sua chinh sach Cap phat thiet bi...

cd backend

REM Load DATABASE_URL from .env file if exists, otherwise use default
if exist .env (
    for /f "tokens=2 delims==" %%a in ('findstr "DATABASE_URL" .env') do set DATABASE_URL=%%a
    REM Remove quotes if present
    set DATABASE_URL=%DATABASE_URL:"=%
) else (
    REM Default DATABASE_URL (adjust if needed)
    set DATABASE_URL=postgresql://postgres:postgres@localhost:5432/asset_rmg_db
)

echo Generating Prisma Client...
call npx prisma generate

echo Running policy script...
call npm run add-equipment-policy

echo.
echo Hoan tat! Chinh sach Cap phat thiet bi da duoc them/chinh sua.
echo Truy cap: http://localhost:5173/policies de xem.

pause
