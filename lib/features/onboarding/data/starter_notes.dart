class StarterNotes {
  static const String welcomeNoteContent = '''# Welcome to Meridian

Meridian is a private, offline-first personal workspace for your thoughts and journals. All notes are saved as standard Markdown files directly on your device, giving you complete ownership and security.
1. **Absolute Privacy**: All notes live on your device as standard Markdown files.
2. **Wikilink Relationships**: Connect your notes dynamically using `[[` links.
3. **Immersive Aesthetics**: Beautiful themes designed to let you focus on writing.

## What is Meridian?
Meridian is designed to be a quiet space for your thoughts. Unlike traditional linear note-taking apps, it allows you to connect ideas together to form an interconnected network of your thoughts.

## Next Steps
- Try exploring [[Getting Started with Wikilinks]] to learn how to connect thoughts.
- Check out [[The Magic of Daily Journaling]] to learn about calendar logs.

#notes #welcome''';

  static const String wikilinksNoteContent = '''# Getting Started with Wikilinks

Wikilinks are the foundation of relational thinking in Meridian. They allow you to build connections between ideas effortlessly.

## How to Create a Link
1. While typing, open two square brackets: `[[`
2. Type the name of another note.
3. Close the brackets: `]]`

For example, this link points back to [[Welcome to Meridian]].

## Backlinks and Ghost Notes
- **Backlinks**: Open the panel at the bottom of the editor to see all other notes that link to the current note.
- **Ghost Notes**: If you link to a note that doesn't exist yet, Meridian creates a "ghost placeholder" for it. It will fully blossom once you open and write in it!

#wikilinks #tutorial''';

  static const String journalNoteContent = '''# The Magic of Daily Journaling

Daily Journaling is a structured habit of reflection. Meridian integrates your daily logs directly into your notes.

## Daily Note Habits
- Use the **Journal** tab to open today's dedicated calendar note.
- Jot down raw thoughts, tasks, and bookmarks.
- Tag your entries with #journal or #reflection to organize them.

## Connect Your Thoughts
Don't let your daily reflections stay isolated! Link today's journal entry to other notes in your system. For instance:
- "Today I spent time writing and connecting thoughts in [[Welcome to Meridian]]."

#journal #productivity''';
}
