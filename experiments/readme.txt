1) Tree::Simple:XS
Globales Array-System
Nodes = nur IDs
Struktur komplett extern gespeichert
→ sehr schnell, aber globaler Zustand

2) Tree + Node (Delegation)
Tree hält Struktur
Node delegiert alle Operationen an Tree
Nodes sind dünne Wrapper
→ klare Trennung, zentraler Controller

3) Node + Tree + Data (separat)
Data = reiner Inhalt
Tree = Struktur + Speicherung
Node = Proxy
→ saubere Schichten (Inhalt / Struktur / Interface)

4) Node + Data + Tree minimal
Data + Struktur stark getrennt
Tree nur ID-Manager + Speicher
Node ist Proxy + Zugriffsschicht
→ stärker modularisiert als (3)

5) Binary / Packed Storage
Tree speichert alles als Binärstrings
Node liest via Byte-Offsets
→ extrem low-level + performance-orientiert

6) Hybrid Data + Tree + Node
Data getrennt
Tree verwaltet Struktur
Node vermittelt zwischen beiden
→ sehr saubere Architektur + klassische OOP-Trennung

7) Fully Object-linked Nodes + Tree registry
Nodes enthalten komplette Struktur selbst
Tree nur Index/Registry
→ OOP-lastig, wenig zentrale Kontrolle

8) Ref-based Node network + minimal Tree
Nodes komplett verlinkt (Parent/Child/Sibling)
Tree nur ID + Lookup
→ stärkstes „echtes Objektgraph“-Modell

🔥 Gesamtvergleich (Kurzklassifikation)
A) Speicherzentriert (nicht OOP)
(1) Fast
(5) Binary

👉 Fokus: Performance, Indexing, Memory Layout

B) Hybrid (klassisch sauber)
(2), (3), (4), (6)

👉 Fokus: Architektur, Trennung, Wartbarkeit

C) Objektgraph (OOP pur)
(7), (8)

👉 Fokus: natürliche Objektbeziehungen, weniger zentrale Kontrolle

🧠 Hauptunterschiede entlang 3 Achsen
1. Speicherort der Struktur
Global (1)
Tree-Array (2–6)
Node selbst (7–8)
Binär (5)

2. Rolle des Trees
zentraler Speicher: (1,2,3,4,5,6)
nur Registry: (7,8)

3. Node-Komplexität
minimal: (1)
mittel: (2–6)
maximal: (7–8)

🧾 Kurzfazit
(1) & (5) → maximale Performance, minimale OOP
(2–6) → saubere Architektur-Designs
(7–8) → klassisches Objektmodell mit stark vernetzten Nodes

👉 Entwicklung geht von:

„Datenstruktur in Arrays“ → „saubere Architektur“ → „vollständiger Objektgraph“

