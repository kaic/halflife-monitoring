# Contributing to HalfLife Monitoring

Thank you for considering contributing to HalfLife Monitoring! 🎉

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- System information (Windows version, GPU model, etc.)

### Suggesting Features

Feature requests are welcome! Please include:
- Use case and motivation
- Proposed implementation (if you have ideas)
- Alternatives you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- **C#**: Follow standard C# conventions
- **INI**: Keep formatting consistent with existing skin
- **Comments**: Write clear, concise comments for complex logic

### Testing

Before submitting, please test:
- TempBridge builds and runs without errors
- Rainmeter skin loads correctly
- All metrics display properly
- No performance regressions

## Development Setup

### Prerequisites
- .NET 8.0 SDK
- Rainmeter 4.5+
- Git

### Build Instructions

```bash
git clone https://github.com/yourusername/halflife-monitoring.git
cd halflife-monitoring/TempBridge
dotnet restore
dotnet build
```

## Questions?

Feel free to open a discussion or reach out via issues!

---

Thank you for contributing! 🙏
