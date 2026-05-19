// Example usage of the academic-notes template
// This demonstrates how to use the template for academic notes

#import "template.typ": *

#show: academic-notes.with(
  // --- Required
  title: "Autonomous robots and agents",
  subtitle: "Unimi - Master's Degree in Computer Science",
  authors: (
    ("Luca Corradini", "https://github.com/LucaCorra02"),
    ("Giacomo Comitani", "https://github.com/comitanigiacomo"),
  ),
  lang: "en", // or "it", IMPORTANT!

  // --- Optional, uncomment to change
  repo-url: "https://github.com/your-username/repo-name",
  course-url: "https://university/professor/course",
  year: "2025-26",
  lecturer: "Professor",
  // date: datetime.today(),
  // license: "CC-BY-4.0",
  // license-url: "https://creativecommons.org/licenses/by/4.0/",
  // heading-numbering: "1.1.",
  // equation-numbering: none,
  // page-numbering: "1",

  // --- Optional with language-based defaults, uncomment to change
  // introduction: auto,
  // last-modified-label: auto,
  // outline-title: auto,
  // part-label: auto,
  // note-title: auto,
  // warning-title: auto,
  // informally-title: auto,
  // example-title: auto,
  // proof-title: auto,
  // theorem-title: auto,
  // theorem-label: auto,
  // equation-supplement: auto,
  // figure-supplement: auto,
)

// ============================================================================
// YOUR CONTENT STARTS HERE
// ============================================================================

#part("First Part")
#include "chapters/Lezione2.typ"

#include "chapters/rotations.typ"
#include "chapters/Lezione4.typ"
#include "chapters/Lezione5.typ"
#include "chapters/Lesson6.typ"
#include "chapters/Lesson10.typ"
