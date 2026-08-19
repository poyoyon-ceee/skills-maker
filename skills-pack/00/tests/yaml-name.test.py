from pathlib import Path
import sys

try:
    import yaml
except ImportError:
    print("SKIP: PyYAML is not installed")
    sys.exit(0)

skill = Path(__file__).resolve().parents[1] / "SKILL.md"
assert skill.exists(), "00/SKILL.md is missing"

text = skill.read_text(encoding="utf-8")
assert text.startswith("---"), "SKILL.md missing frontmatter"
parts = text.split("---", 2)
assert len(parts) >= 3, "SKILL.md missing closing frontmatter"

data = yaml.safe_load(parts[1])
assert isinstance(data.get("name"), str), f"name must be a string, got {type(data.get('name')).__name__}"
assert data["name"] == "00"
assert data.get("disable-model-invocation") is True
print("ok")
