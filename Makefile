# Makefile for Flutter Test Pilot

.PHONY: help test test-unit test-integration test-comprehensive test-all coverage clean format lint analyze

help: ## Show this help message
	@echo "Flutter Test Pilot - Make Commands"
	@echo "=================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## Run unit tests (default)
	@echo "🧪 Running unit tests..."
	@flutter test

test-unit: ## Run only unit tests
	@echo "🧪 Running unit tests..."
	@flutter test test/unit/

test-integration: ## Run integration tests (requires device)
	@echo "🧪 Running integration tests..."
	@cd example && flutter test integration_test/

test-comprehensive: ## Run comprehensive manual tests
	@echo "🧪 Running comprehensive tests..."
	@dart test/comprehensive_test.dart

test-all: ## Run all tests (unit + integration + comprehensive)
	@echo "🧪 Running all tests..."
	@./test_runner.sh --all

coverage: ## Generate test coverage report
	@echo "📊 Generating coverage report..."
	@flutter test --coverage
	@if command -v lcov >/dev/null 2>&1; then \
		genhtml coverage/lcov.info -o coverage/html; \
		echo "✅ Coverage report generated at coverage/html/index.html"; \
	else \
		echo "⚠️  Install lcov to generate HTML report: brew install lcov (Mac) or sudo apt-get install lcov (Linux)"; \
	fi

clean: ## Clean build artifacts and cache
	@echo "🧹 Cleaning..."
	@flutter clean
	@rm -rf build/
	@rm -rf coverage/
	@cd example && flutter clean

format: ## Format all Dart files
	@echo "✨ Formatting code..."
	@dart format .

lint: ## Run linter
	@echo "🔍 Running linter..."
	@flutter analyze

analyze: ## Run static analysis
	@echo "🔍 Running static analysis..."
	@flutter analyze --fatal-infos

fix: ## Apply automated fixes
	@echo "🔧 Applying fixes..."
	@dart fix --apply

get: ## Get dependencies
	@echo "📦 Getting dependencies..."
	@flutter pub get

upgrade: ## Upgrade dependencies
	@echo "⬆️  Upgrading dependencies..."
	@flutter pub upgrade

build-example: ## Build example app
	@echo "🏗️  Building example app..."
	@cd example && flutter build apk

install: ## Install CLI globally
	@echo "📥 Installing CLI..."
	@dart pub global activate --source path .

run-example: ## Run example app
	@echo "🚀 Running example app..."
	@cd example && flutter run

check: format lint test ## Run format, lint, and tests
	@echo "✅ All checks passed!"

ci: clean get analyze test ## CI pipeline (clean, get, analyze, test)
	@echo "✅ CI checks completed!"

.DEFAULT_GOAL := help
