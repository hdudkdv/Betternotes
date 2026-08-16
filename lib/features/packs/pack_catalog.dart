import 'package:flutter/material.dart';

import '../entitlements/entitlement_model.dart';

class PackDef {
  const PackDef({
    required this.key,
    required this.icon,
    required this.titleDe,
    required this.titleEn,
    required this.bodyDe,
    required this.bodyEn,
    required this.toolsDe,
    required this.toolsEn,
  });

  final String key;
  final IconData icon;
  final String titleDe;
  final String titleEn;
  final String bodyDe;
  final String bodyEn;
  final List<String> toolsDe;
  final List<String> toolsEn;

  String title(bool german) => german ? titleDe : titleEn;
  String body(bool german) => german ? bodyDe : bodyEn;
  List<String> tools(bool german) => german ? toolsDe : toolsEn;
}

class MarketplaceGroup {
  const MarketplaceGroup({
    required this.id,
    required this.titleDe,
    required this.titleEn,
    required this.keys,
  });

  final String id;
  final String titleDe;
  final String titleEn;
  final List<String> keys;

  String title(bool german) => german ? titleDe : titleEn;
}

abstract final class PackCatalog {
  static PackDef? byKey(String key) {
    for (final pack in all) {
      if (pack.key == key) return pack;
    }
    return null;
  }

  /// Shared Marketplace / Packs grouping of extras we already have.
  static const groups = <MarketplaceGroup>[
    MarketplaceGroup(
      id: 'study',
      titleDe: 'Lernen & Schule',
      titleEn: 'Study & school',
      keys: [
        FeatureKeys.aiAssistant,
        FeatureKeys.packEdu,
        FeatureKeys.packAcademic,
        FeatureKeys.calcPlus,
        FeatureKeys.formulaPack,
        FeatureKeys.chartPack,
        FeatureKeys.helperPack,
      ],
    ),
    MarketplaceGroup(
      id: 'work',
      titleDe: 'Arbeit & Organisation',
      titleEn: 'Work & organisation',
      keys: [
        FeatureKeys.packAgile,
        FeatureKeys.packFreelance,
        FeatureKeys.packDev,
      ],
    ),
    MarketplaceGroup(
      id: 'life',
      titleDe: 'Kreativ & Alltag',
      titleEn: 'Creative & everyday',
      keys: [
        FeatureKeys.packRpg,
        FeatureKeys.packMusic,
        FeatureKeys.packCulinary,
        FeatureKeys.packFitness,
        FeatureKeys.packTravel,
      ],
    ),
  ];

  static const all = <PackDef>[
    PackDef(
      key: FeatureKeys.packDev,
      icon: Icons.terminal_rounded,
      titleDe: 'Developer & Coder',
      titleEn: 'Developer & Coder',
      bodyDe:
          'Code-Blöcke mit Hervorhebung, Snippet-Manager und Terminal-Look für IT und Web.',
      bodyEn:
          'Highlighted code blocks, a snippet manager, and a terminal look for IT and web.',
      toolsDe: ['Code-Block', 'Snippets', 'Terminal-Karte'],
      toolsEn: ['Code block', 'Snippets', 'Terminal card'],
    ),
    PackDef(
      key: FeatureKeys.packEdu,
      icon: Icons.style_outlined,
      titleDe: 'Education & Flashcards',
      titleEn: 'Education & Flashcards',
      bodyDe:
          'Fragen zu Karteikarten (Spaced Repetition), Vorlesungs-Marken und Notenrechner.',
      bodyEn:
          'Turn questions into spaced-repetition cards, lecture marks, and a grade calculator.',
      toolsDe: ['Karteikarten', 'Vorlesungs-Marken', 'Notenrechner'],
      toolsEn: ['Flashcards', 'Lecture marks', 'Grade calculator'],
    ),
    PackDef(
      key: FeatureKeys.packRpg,
      icon: Icons.auto_stories_outlined,
      titleDe: 'Worldbuilding & RPG',
      titleEn: 'Worldbuilding & RPG',
      bodyDe:
          'Zeitstrahl, Charakter-Steckbrief mit Stats und ein einfacher Dialogbaum.',
      bodyEn:
          'A timeline, character sheets with stats, and a simple dialogue tree.',
      toolsDe: ['Zeitstrahl', 'Charakter', 'Dialogbaum'],
      toolsEn: ['Timeline', 'Character', 'Dialogue tree'],
    ),
    PackDef(
      key: FeatureKeys.packCulinary,
      icon: Icons.restaurant_outlined,
      titleDe: 'Culinary & Recipe',
      titleEn: 'Culinary & Recipe',
      bodyDe:
          'Zutaten skalieren, Cups/Fahrenheit umrechnen und Back-Timer starten.',
      bodyEn:
          'Scale ingredients, convert cups/Fahrenheit, and start a bake timer.',
      toolsDe: ['Skalierer', 'Einheiten', 'Timer'],
      toolsEn: ['Scaler', 'Units', 'Timer'],
    ),
    PackDef(
      key: FeatureKeys.packAgile,
      icon: Icons.view_kanban_outlined,
      titleDe: 'Agile Productivity',
      titleEn: 'Agile Productivity',
      bodyDe: 'Kanban-Board, Pomodoro in der Seitenleiste und Habit-Tracker.',
      bodyEn: 'Kanban board, a Pomodoro timer, and a habit tracker.',
      toolsDe: ['Kanban', 'Pomodoro', 'Habits'],
      toolsEn: ['Kanban', 'Pomodoro', 'Habits'],
    ),
    PackDef(
      key: FeatureKeys.packMusic,
      icon: Icons.music_note_outlined,
      titleDe: 'Musician & Songwriter',
      titleEn: 'Musician & Songwriter',
      bodyDe: 'Akkorde über Text, Metronom und Silben-/Reimhilfe.',
      bodyEn: 'Chords over lyrics, a metronome, and syllable/rhyme help.',
      toolsDe: ['Akkorde', 'Metronom', 'Silben & Reim'],
      toolsEn: ['Chords', 'Metronome', 'Syllables & rhyme'],
    ),
    PackDef(
      key: FeatureKeys.packAcademic,
      icon: Icons.school_outlined,
      titleDe: 'Academic & Research',
      titleEn: 'Academic & Research',
      bodyDe: 'Zitation (APA/Harvard), Zitat-Karte und Formel-Block.',
      bodyEn: 'Citations (APA/Harvard), a quote card, and a formula block.',
      toolsDe: ['Zitation', 'Zitat', 'Formel'],
      toolsEn: ['Citation', 'Quote', 'Formula'],
    ),
    PackDef(
      key: FeatureKeys.packFitness,
      icon: Icons.fitness_center_outlined,
      titleDe: 'Health & Fitness',
      titleEn: 'Health & Fitness',
      bodyDe: 'Workout-Logger, Pausen-Timer und Fortschrittslinie.',
      bodyEn: 'Workout logger, rest timer, and a progress line.',
      toolsDe: ['Workout', 'Pause', 'Graph'],
      toolsEn: ['Workout', 'Rest', 'Graph'],
    ),
    PackDef(
      key: FeatureKeys.packTravel,
      icon: Icons.travel_explore_outlined,
      titleDe: 'Travel & Nomad',
      titleEn: 'Travel & Nomad',
      bodyDe: 'Ortspin, Währung/Zeitzone und Packlisten nach Klima.',
      bodyEn: 'Place pins, currency/timezone, and climate packing lists.',
      toolsDe: ['Ort', 'Umrechner', 'Packliste'],
      toolsEn: ['Place', 'Convert', 'Packing list'],
    ),
    PackDef(
      key: FeatureKeys.packFreelance,
      icon: Icons.badge_outlined,
      titleDe: 'Freelancer & CRM',
      titleEn: 'Freelancer & CRM',
      bodyDe: 'Zeiterfassung, Kundenkarte und Mini-Rechnung als PDF.',
      bodyEn: 'Time tracker, a client card, and a mini invoice PDF.',
      toolsDe: ['Zeit', 'Kunde', 'Rechnung'],
      toolsEn: ['Time', 'Client', 'Invoice'],
    ),
  ];
}
