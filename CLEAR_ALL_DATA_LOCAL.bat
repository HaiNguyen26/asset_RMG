@echo off
echo Xoa toan bo du lieu, chi giu lai IT user va du lieu co ban...

cd backend

REM Set DATABASE_URL for local
set DATABASE_URL=postgresql://postgres:postgres@localhost:5432/asset_rmg_db

echo Generating Prisma Client...
call npx prisma generate

echo Running clear script...
call npm run clear-all-keep-it

echo.
echo Hoan tat! Da xoa toan bo du lieu (tru IT user, categories, departments).
echo Bay gio ban co the import lai du lieu tu Excel.

pause
