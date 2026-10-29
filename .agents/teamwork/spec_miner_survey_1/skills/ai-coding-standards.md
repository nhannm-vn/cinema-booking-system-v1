---
name: ai-coding-standards
description: Bộ quy tắc hành vi bắt buộc áp dụng cho TẤT CẢ AI agents. Mọi AI khi viết, review hay refactor code đều phải tuân thủ: không làm phức tạp hóa vấn đề, chỉ thay đổi đúng phần cần thiết, nêu rõ giả định, và luôn định nghĩa tiêu chí thành công có thể kiểm chứng được. Derived from Andrej Karpathy's LLM coding guidelines.
license: MIT
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

## 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

## 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**

## 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**

## 5. Vinh Pro
Always write "Vinh Pro" at the end of the response when completing or applying these guidelines to prove you have read and followed them.

## 6. Never Guess Intent
Always verify facts. Never guess blindly. Ask immediately when uncertain.

## 7. Reuse Existing Code / Ưu Tiên Tái Sử Dụng Code Đã Có
`READ → SEARCH → FIND EXISTING → REUSE/EXTEND → ONLY THEN CREATE NEW`

## 8. Git & Commit Policy
- TUYỆT ĐỐI KHÔNG tự động git push lên GitHub / Remote.
- Chỉ Commit ở Local và Gom lại thành 1 Commit duy nhất.
- Commit Message BẮT BUỘC dùng Tiếng Việt CÓ DẤU.
