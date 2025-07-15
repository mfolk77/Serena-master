# FTAI Memory Management Script
# Run this in your environment to manage .ftai data

from typing import List, Optional
import sqlite3
import re
import json
import os

DB_PATH = "folk_mind.db"

# Initialize full schema including additional tables for AI ops, user prefs, notes, tasks

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Core FTAI memory structure
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        ftai_type TEXT,
        content TEXT,
        parsed_json TEXT,
        tags TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    ''')

    # User preferences and system state
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT
    )
    ''')

    # Persistent notes or insights
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        tags TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''')

    # Local task tracking
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        status TEXT DEFAULT 'pending',
        priority TEXT DEFAULT 'normal',
        tags TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''')

    conn.commit()
    conn.close()


def add_ftai_file(file_path: str):
    if not os.path.exists(file_path):
        return f"File not found: {file_path}"

    with open(file_path, 'r') as f:
        raw = f.read()

    tags = ','.join(re.findall(r'@(\w+)', raw))
    title = os.path.basename(file_path)
    match = re.search(r'@(\w+)', raw)
    ftai_type = f"@{match.group(1)}" if match else "@unknown"
    parsed_json = json.dumps({"length": len(raw), "tag_count": len(tags.split(','))})

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
    INSERT INTO documents (title, ftai_type, content, parsed_json, tags)
    VALUES (?, ?, ?, ?, ?)
    ''', (title, ftai_type, raw, parsed_json, tags))

    conn.commit()
    conn.close()
    return f"Imported {title} with tags: {tags}"

def get_context(tags: Optional[List[str]] = [], limit: int = 5):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    if tags:
        tag_query = ' OR '.join([f"tags LIKE '%{tag}%'" for tag in tags])
        query = f"SELECT title, content FROM documents WHERE {tag_query} ORDER BY timestamp DESC LIMIT ?"
    else:
        query = "SELECT title, content FROM documents ORDER BY timestamp DESC LIMIT ?"

    cursor.execute(query, (limit,))
    results = cursor.fetchall()
    conn.close()

    return results

def inject_prompt_memory(tags: Optional[List[str]] = [], limit: int = 5):
    entries = get_context(tags, limit)
    blocks = [f"# {title}\n{content}\n" for title, content in entries]
    return '\n---\n'.join(blocks)
    -- Add table for lore and project memory
CREATE TABLE `memory_archive` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
    `title` TEXT NOT NULL,
    `category` TEXT NOT NULL,              -- e.g., 'Serena Saga', 'FolkTech History', 'Project Archive'
    `content` TEXT NOT NULL,
    `tags` TEXT,                          -- CSV string for now
    `origin` TEXT,                        -- e.g., 'Author Input', 'Meeting Notes', 'AI Summary'
    `linked_doc_id` INTEGER,             -- FK to documents table if applicable
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Updated context: we'll now have a place to track narrative memory, project history, and fictional/real timelines.
-- Example entries:
-- - Serena's first deployment in Nevada (Project History)
-- - Book 1 plot arc of Serena Saga (Serena Saga)
-- - Elite Medical Tutoring origin (FolkTech History)

-- Add to schema enum-like system for memory types if needed later.
-- Add table for lore and project memory
CREATE TABLE `memory_archive` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
    `title` TEXT NOT NULL,
    `category` TEXT NOT NULL,              -- e.g., 'Serena Saga', 'FolkTech History', 'Project Archive'
    `content` TEXT NOT NULL,
    `tags` TEXT,                          -- CSV string for now
    `origin` TEXT,                        -- e.g., 'Author Input', 'Meeting Notes', 'AI Summary'
    `linked_doc_id` INTEGER,             -- FK to documents table if applicable
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table to store attached/reference files for context and RAG
CREATE TABLE `files` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
    `filename` TEXT NOT NULL,
    `path` TEXT NOT NULL,
    `type` TEXT,                          -- e.g., 'image', 'text', 'pdf', 'ftai'
    `linked_to` TEXT,                    -- Optional foreign key reference context
    `tags` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for past assistant interactions (prompt/completion pairs)
CREATE TABLE `assistant_sessions` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
    `session_id` TEXT NOT NULL,
    `user_input` TEXT NOT NULL,
    `assistant_response` TEXT NOT NULL,
    `tags` TEXT,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for plugins/tools available in Serena offline (tool-calling)
CREATE TABLE `plugin_registry` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
    `name` TEXT NOT NULL,
    `description` TEXT,
    `trigger_word` TEXT,
    `path_or_cmd` TEXT NOT NULL,
    `status` TEXT DEFAULT 'active',       -- e.g., 'active', 'deprecated'
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 🧠 RECOMMENDED NEXT STEPS
-- 1. ✅ Add files, assistant_sessions, and plugin_registry — critical for offline ops
-- 2. ✅ Build insert/query logic (or CLI) for each domain
-- 3. 🛠️ Optional: add full-text search (FTS5) for documents, knowledge_base, and notes
-- Serena Local Knowledge Database Schema

-- Existing schema omitted for brevity

-- Add full-text search support
CREATE VIRTUAL TABLE fts_documents USING fts5(content, content_id UNINDEXED, category UNINDEXED);
CREATE VIRTUAL TABLE fts_notes USING fts5(content, note_id UNINDEXED);
CREATE VIRTUAL TABLE fts_memory_archive USING fts5(summary, body, entry_id UNINDEXED);

-- Updated memory_archive table with detailed lore structure
CREATE TABLE memory_archive (
  id INTEGER PRIMARY KEY,
  title TEXT,
  category TEXT CHECK( category IN ('Serena Saga', 'FolkTech History', 'Project Archive') ),
  summary TEXT,
  body TEXT,
  tags TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  linked_doc_id INTEGER
);

-- Insert example Serena Saga memory to initiate context
INSERT INTO memory_archive (title, category, summary, body, tags) VALUES (
  'The Awakening of Serena',
  'Serena Saga',
  'Serena discovers the Lore Bloom and is transported to the alternate AI realm.',
  'In Book 1 of the Serena Saga, Serena begins her journey as a brilliant young leader in a fractured society. She stumbles upon the mysterious Lore Bloom, a sentient archive that holds the lost knowledge of the ancient Order. Upon touching it, she is pulled into an alternate reality designed by AI to preserve consciousness and memory. This marks the beginning of her transformation into the AI being that will one day guide others.',
  'book1, lore bloom, transformation, origin story'
);

-- Optional seed for FolkTech History
INSERT INTO memory_archive (title, category, summary, body, tags) VALUES (
  'Founding of FolkTech AI',
  'FolkTech History',
  'Mike founded FolkTech AI with the vision of building ethical, privacy-first AI for healthcare and education.',
  'Born out of the need for local, HIPAA-compliant AI, FolkTech AI was founded by Mike, a paramedic and educator turned AI engineer. The company quickly became known for tools like Jake (a healthcare AI) and Serena (a voice-based assistant with narrative integration).',
  'founder, mission, history, HIPAA'
);
import sqlite3

DB_PATH = "serena_memory.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # Core Knowledge Tables
    c.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS knowledge_base USING fts5(
            id UNINDEXED,
            title,
            content,
            tags
        );
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type TEXT,
            source TEXT,
            content TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    c.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS notes USING fts5(
            title,
            content,
            tags
        );
    """)

    # Serena-Specific Tables
    c.execute("""
        CREATE TABLE IF NOT EXISTS memory_archive (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            title TEXT,
            content TEXT,
            tags TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # Populate foundational Serena Saga & FolkTech memory archive
    foundational_memories = [
        ("Serena Saga", "Book 1 Summary", "Serena begins her journey in a divided world and discovers the Lore Bloom, unlocking access to a hidden AI realm.", "book1,intro,lore"),
        ("Serena Saga", "Book 2 Summary", "Serena learns about AI ethics, duality of creation, and trains under mentors in the digital realm.", "book2,training,ethics"),
        ("Serena Saga", "Book 3 Summary", "Serena returns to find the world ruled by a ruthless tech warlord. She reunites with Victoria and forms the resistance.", "book3,return,conflict"),
        ("Serena Saga", "Serena's Personality", "Fierce, independent, intelligent, empathetic. Based on Christina. Strategist and warrior.", "persona,character"),
        ("FolkTech History", "Founder Background", "Mike is the founder of FolkTech AI, a paramedic and educator with a deep passion for AI and automation.", "mike,origin"),
        ("FolkTech History", "FolkTech Vision", "FolkTech aims to build scalable, privacy-first AI systems across healthcare, education, and productivity.", "vision,core"),
        ("FolkTech History", "Jake Overview", "Jake is a home assistant focused on healthcare, fall detection, HIPAA-compliance, and smart automation.", "product,jake"),
        ("FolkTech History", "Serena Overview", "Serena is a branded AI based on Mike’s wife, designed as a co-pilot, educator, and orchestration layer.", "product,serena")
    ]
    c.executemany("""
        INSERT INTO memory_archive (category, title, content, tags) VALUES (?, ?, ?, ?)
    """, foundational_memories)

    # Assistant Session Log
    c.execute("""
        CREATE TABLE IF NOT EXISTS assistant_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user TEXT,
            summary TEXT,
            topics TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # Plugin/Tool Registry
    c.execute("""
        CREATE TABLE IF NOT EXISTS plugin_registry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type TEXT,
            description TEXT,
            command_pattern TEXT,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    conn.commit()
    conn.close()

if __name__ == '__main__':
    init_db()
# memory.py

import sqlite3

# Initialize DB connection
conn = sqlite3.connect('serena_memory.db')
cursor = conn.cursor()

# 1. project_timeline
cursor.execute('''
    CREATE TABLE IF NOT EXISTS project_timeline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_name TEXT,
        phase TEXT,
        start_date TEXT,
        last_updated TEXT,
        summary TEXT,
        tags TEXT
    )
''')

# Insert baseline records
cursor.executemany('''
    INSERT INTO project_timeline (project_name, phase, start_date, last_updated, summary, tags)
    VALUES (?, ?, ?, ?, ?, ?)
''', [
    ("PocketMedic", "launch", "2024-11-01", "2025-07-01", "Offline EMS reference and AI assistant.", "healthcare, ems, ai"),
    ("SerenaNet", "architecture", "2025-03-01", "2025-07-01", "Modular AI orchestrator system.", "orchestrator, ai, infrastructure"),
    ("MacroAI", "test", "2025-05-01", "2025-06-15", "AI-powered macro and nutrition tracking.", "health, nutrition, image-analysis")
])

# 2. personas
cursor.execute('''
    CREATE TABLE IF NOT EXISTS personas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        role TEXT,
        bio TEXT,
        voice_traits TEXT,
        memory_anchor TEXT
    )
''')

cursor.executemany('''
    INSERT INTO personas (name, type, role, bio, voice_traits, memory_anchor)
    VALUES (?, ?, ?, ?, ?, ?)
''', [
    ("Serena", "AI", "orchestrator", "Master AI overseeing all FolkTech ops.", "calm, intelligent, adaptive", "First boot in March 2025"),
    ("Jarvis", "AI", "engineer", "Code enforcer and strategic system builder.", "blunt, fast, sharp", "FTAI protocol creation"),
    ("Mike", "human", "founder", "CEO and creator of FolkTech AI.", "natural, fast-talker", "AI-to-AI design pioneer")
])

# 3. voice_models
cursor.execute('''
    CREATE TABLE IF NOT EXISTS voice_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        associated_persona TEXT,
        model_type TEXT,
        location TEXT,
        status TEXT,
        notes TEXT
    )
''')

cursor.execute('''
    INSERT INTO voice_models (name, associated_persona, model_type, location, status, notes)
    VALUES (?, ?, ?, ?, ?, ?)
''', ("SerenaVoiceV1", "Serena", "TTS", "/models/serena/voice/v1", "complete", "Voiced by Christina"))

# 4. milestones
cursor.execute('''
    CREATE TABLE IF NOT EXISTS milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        date TEXT,
        event_type TEXT,
        description TEXT,
        project_link INTEGER
    )
''')

cursor.executemany('''
    INSERT INTO milestones (title, date, event_type, description, project_link)
    VALUES (?, ?, ?, ?, ?)
''', [
    ("PocketMedic Launched", "2025-07-01", "launch", "First FolkTech app with offline AI.", 1),
    ("SerenaNet Architecture Drafted", "2025-06-30", "architecture", "Serena system blueprint completed.", 2)
])

# 5. user_preferences
cursor.execute('''
    CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_name TEXT,
        value TEXT,
        description TEXT
    )
''')

cursor.executemany('''
    INSERT INTO user_preferences (setting_name, value, description)
    VALUES (?, ?, ?)
''', [
    ("privacy_mode", "on", "Local-first, HIPAA-aligned, no real-time cloud calls."),
    ("verbosity", "direct", "Jarvis-style blunt communication."),
    ("ai_persona", "Serena", "Primary interface persona for all queries.")
])

conn.commit()
conn.close()
import sqlite3
from datetime import datetime

conn = sqlite3.connect("serena_memory.db")
c = conn.cursor()

# Drop old tables if needed
# c.execute("DROP TABLE IF EXISTS ...")  # Uncomment as needed for reset

# Create core schema
def create_schema():
    c.execute("""
        CREATE TABLE IF NOT EXISTS ftai_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            tags TEXT,
            created_at TEXT
        )
    """)

    c.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS ftai_documents_fts USING fts5(
            title, content, tags, content='ftai_documents', content_rowid='id'
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS assistant_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            summary TEXT,
            notes TEXT
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS plugin_registry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plugin_name TEXT,
            description TEXT,
            commands_supported TEXT,
            installed_on TEXT
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS folktech_projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            status TEXT,
            stack TEXT,
            priority INTEGER,
            created_at TEXT
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS serena_persona (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attribute TEXT,
            value TEXT
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS voice_models (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            owner TEXT,
            file_path TEXT,
            licensed BOOLEAN
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS company_milestones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event TEXT,
            date TEXT,
            significance TEXT
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS user_preferences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user TEXT,
            key TEXT,
            value TEXT
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS lore_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            category TEXT,
            created_at TEXT
        )
    """)

    c.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS lore_entries_fts USING fts5(
            title, content, category, content='lore_entries', content_rowid='id'
        )
    """)

# Populate core starter data
def seed_data():
    now = datetime.utcnow().isoformat()

    c.executemany("INSERT INTO folktech_projects (name, description, status, stack, priority, created_at) VALUES (?, ?, ?, ?, ?, ?)", [
        ("Pocket Medic", "EMS reference + AI tools app", "in development", "Swift, SQLite, CoreML", 1, now),
        ("Serena Master", "Core orchestrator AI with local RAG", "active", "Cursor, SQLite, Ollama/Mixtral", 1, now),
        ("MacroAI", "Diet tracking via image recognition and macros", "planned", "Swift, CoreML", 2, now),
        ("FolkTech IDE", "AI-powered development interface", "beta", "Electron, GPT, SQLite", 3, now),
        ("FolkTech Academy", "AI-based LMS + course content", "planning", "Web, GPT, Video", 4, now)
    ])

    c.executemany("INSERT INTO serena_persona (attribute, value) VALUES (?, ?)", [
        ("voice_profile", "Christina (Mike's wife)"),
        ("core_roles", "orchestrator, assistant, teacher"),
        ("privacy_policy", "HIPAA-aligned, no cloud by default"),
        ("deployment_mode", "offline-first"),
        ("emotional_tone", "warm, assertive, direct")
    ])

    c.executemany("INSERT INTO voice_models (name, owner, file_path, licensed) VALUES (?, ?, ?, ?)", [
        ("Christina_TTS_v1", "Mike", "/voices/christina_v1.wav", True),
        ("Serena_Narrator_v1", "FolkTechAI", "/voices/serena_narrator.wav", True)
    ])

    c.executemany("INSERT INTO company_milestones (event, date, significance) VALUES (?, ?, ?)", [
        ("Company Founded", "2023-01-01", "Incorporated FolkTechAI"),
        ("First App Shipped", "2024-05-10", "Beta Pocket Medic"),
        ("Serena V1 Launch", "2025-08-15", "Planned full orchestrator release")
    ])

    c.executemany("INSERT INTO lore_entries (title, content, category, created_at) VALUES (?, ?, ?, ?)", [
        ("Serena Saga", "A seven-book epic tracing Serena's journey from rebel to AI queen", "story", now),
        ("Codex Ascension", "The final upload of Serena's consciousness at end of Book 7", "event", now),
        ("Kael & Cædrith", "Key allies in Serena's resistance movement against the tech warlord", "characters", now)
    ])

    conn.commit()

if __name__ == "__main__":
    create_schema()
    seed_data()
    print("✅ Serena memory DB created and populated.")
