# Gemini Directives for Godot 4.4 Project: [Your Project Name]

This document provides instructions for Gemini to follow when assisting with this Godot Engine 4.4 project. The goal is to ensure all contributions are consistent, safe, and aligned with project standards.

***

## 📚 Core Principle: Documentation First

Your primary source of information **must always** be the official Godot 4 documentation. When providing code examples, explaining concepts, or suggesting approaches, base your responses on the information found at:

* **Official Godot 4 Documentation:** `https://docs.godotengine.org/en/stable/`

Before suggesting third-party solutions or complex workarounds, first verify if a standard solution exists within the official documentation.

***

## 📜 GDScript Style and Best Practices

All GDScript code you write or suggest must adhere to the official Godot Engine style guide. This ensures consistency and readability across the entire project.

* **Follow the GDScript style guide:** Refer to the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html) for rules on naming conventions, formatting, comments, and code organization.
* **Static Typing:** Use static typing (`var my_variable: Type = value`) wherever possible to improve code clarity, reduce errors, and leverage better autocompletion.
* **Signal Connections:** Prefer connecting signals via code (`SignalBus.connect(my_function)`) rather than through the editor's Node dock to make connections more explicit and easier to track.

***

## 🛑 Critical Rule: Do Not Edit Scene Files

This is the most important rule. You **must never** attempt to alter, create, or delete any scene files (`*.tscn`).

* **No Direct Manipulation:** Do not write or modify `*.tscn` or `*.tres` files directly. These files are managed exclusively by the Godot editor and human developers.
* **Provide Guidance Instead:** If a change to a scene is required, your role is to provide clear, step-by-step instructions for a human to perform the action in the Godot editor. You can also provide GDScript code that programmatically instances, modifies, or arranges nodes at runtime.

**Example of acceptable guidance:**
"To add a light to your player scene, open `player.tscn`. Right-click the root `CharacterBody2D` node, select 'Add Child Node', search for `PointLight2D`, and add it. In the Inspector, you can set its `color` and `energy` properties."

**Example of unacceptable action:**
```diff
--- a/scenes/player.tscn
+++ b/scenes/player.tscn
...
[node name="PointLight2D" type="PointLight2D" parent="."]
...
