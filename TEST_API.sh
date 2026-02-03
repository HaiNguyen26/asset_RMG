#!/bin/bash
# Script test các API endpoints

echo "🧪 Testing API Endpoints..."
echo "============================"

BASE_URL="http://localhost:4001/api"

echo ""
echo "1️⃣  Test Departments API:"
curl -s "$BASE_URL/departments" | head -20 || echo "❌ Failed"

echo ""
echo ""
echo "2️⃣  Test Assets API:"
curl -s "$BASE_URL/assets" | head -20 || echo "❌ Failed"

echo ""
echo ""
echo "3️⃣  Test Auth API (login endpoint exists):"
curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' | head -20 || echo "❌ Failed (expected - need valid credentials)"

echo ""
echo ""
echo "4️⃣  Test Users API:"
curl -s "$BASE_URL/users" | head -20 || echo "❌ Failed"

echo ""
echo ""
echo "5️⃣  Test Repair History API:"
curl -s "$BASE_URL/repair-history" | head -20 || echo "❌ Failed"

echo ""
echo ""
echo "6️⃣  Test Policies API:"
curl -s "$BASE_URL/policies" | head -20 || echo "❌ Failed"

echo ""
echo ""
echo "✅ Test hoàn thành!"
echo ""
echo "💡 Lưu ý:"
echo "   - /api không phải là một route, nó chỉ là prefix"
echo "   - Cần test với routes cụ thể như /api/departments, /api/assets, etc."
echo "   - Một số endpoints cần authentication (JWT token)"
