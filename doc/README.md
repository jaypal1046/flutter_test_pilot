# 📚 Flutter Test Pilot - Documentation Index

Welcome to the Flutter Test Pilot documentation! This folder contains comprehensive guides for all features.

---

## 📖 Quick Links

### Getting Started

- [Main README](../README.md) - Project overview and quick start
- [Real World Usage Guide](./REAL_WORLD_USAGE.md) - How to use in your actual project

### Implementation Guides

- [Implementation Complete](./IMPLEMENTATION_COMPLETE.md) - Phase 2 & 3 complete summary
- [Phase 2 Complete](./PHASE_2_COMPLETE.md) - Native handling implementation details

### Feature Guides

- [Enhanced Tester Guide](./ENHANCED_TESTER_GUIDE.md) - Advanced testing utilities
- [PilotFinder Guide](./PILOT_FINDER_GUIDE.md) - Intelligent widget finding
- [Native Action Handler](./native_action_handler_guide.md) - Native dialog handling
- [Test-Driven Watcher](./test_driven_watcher_guide.md) - Dialog watcher configuration
- [TestSuite Sections](./testsuite_sections_doc.md) - Test organization

### Additional Resources

- [Flutter Test Pilot Docs](./flutter_test_pilot_docs.md) - Complete API documentation

---

## 🎯 Recommended Reading Order

### For New Users

1. [Main README](../README.md) - Understand what Flutter Test Pilot is
2. [Real World Usage Guide](./REAL_WORLD_USAGE.md) - See practical examples
3. [Enhanced Tester Guide](./ENHANCED_TESTER_GUIDE.md) - Learn testing utilities

### For Advanced Features

1. [Phase 2 Complete](./PHASE_2_COMPLETE.md) - Native handling setup
2. [Native Action Handler](./native_action_handler_guide.md) - Configure native features
3. [PilotFinder Guide](./PILOT_FINDER_GUIDE.md) - Advanced widget finding

### For Integration

1. [Implementation Complete](./IMPLEMENTATION_COMPLETE.md) - Full feature overview
2. [Real World Usage Guide](./REAL_WORLD_USAGE.md) - Integration examples
3. [Test-Driven Watcher](./test_driven_watcher_guide.md) - Configure watchers

---

## 📂 Documentation Structure

```
doc/
├── README.md (this file)
├── ENHANCED_TESTER_GUIDE.md         # Advanced testing utilities
├── IMPLEMENTATION_COMPLETE.md       # Phase 2 & 3 summary
├── PHASE_2_COMPLETE.md             # Native handling details
├── PILOT_FINDER_GUIDE.md           # Widget finding strategies
├── REAL_WORLD_USAGE.md             # Practical usage guide
├── flutter_test_pilot_docs.md      # API documentation
├── native_action_handler_guide.md  # Native dialog handling
├── test_driven_watcher_guide.md    # Watcher configuration
└── testsuite_sections_doc.md       # Test organization
```

---

## 🚀 Quick Examples

### Basic Test Run

```bash
flutter_test_pilot run integration_test/login_test.dart
```

### With Native Features

```bash
flutter_test_pilot run integration_test/login_test.dart \
  --app-id=com.example.myapp \
  --native-watcher \
  --pre-grant-permissions=all \
  --disable-animations
```

### Parallel Execution

```bash
flutter_test_pilot run integration_test/ \
  --parallel \
  --concurrency=3 \
  --retry=2
```

---

## 💡 Need Help?

- **Bug Reports**: Create an issue on GitHub
- **Feature Requests**: Open a discussion
- **Questions**: Check the guides above first

---

**Last Updated**: January 21, 2026
