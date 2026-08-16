class GemmaTopic {
  const GemmaTopic({
    required this.id,
    required this.keywords,
    required this.titleDe,
    required this.titleEn,
    required this.bodyDe,
    required this.bodyEn,
  });

  final String id;
  final List<String> keywords;
  final String titleDe;
  final String titleEn;
  final String bodyDe;
  final String bodyEn;

  String title(bool german) => german ? titleDe : titleEn;
  String body(bool german) => german ? bodyDe : bodyEn;
}

/// School-topic explanations. Used when the student asks *why* or
/// does not understand a connection — not to write their essay for them.
abstract final class GemmaTopics {
  static List<GemmaTopic> matchAll(String raw) {
    final s = raw.toLowerCase();
    final hits = <GemmaTopic>[];
    for (final topic in all) {
      if (topic.keywords.any((k) => s.contains(k))) hits.add(topic);
    }
    return hits;
  }

  static GemmaTopic? match(String raw) {
    final hits = matchAll(raw);
    return hits.isEmpty ? null : hits.first;
  }

  static String format(List<GemmaTopic> topics, {required bool german}) {
    return [
      for (final topic in topics)
        '${topic.title(german)}\n${topic.body(german)}',
    ].join('\n\n');
  }

  static String mathConcept(String kind, {required bool german}) {
    return switch (kind) {
      'linear' || 'equation' => german
          ? 'Eine Gleichung bleibt wahr, wenn du auf beiden Seiten dasselbe tust. Deshalb nimmst du erst die Zahl ohne x weg (Umkehroperation) und teilst oder multiplizierst danach. Das Ergebnis rechne ich dir nicht vor.'
          : 'An equation stays true if you do the same thing on both sides. First undo the number without x, then divide or multiply. I will not compute the result for you.',
      'expression' => german
          ? 'Punkt vor Strich: Multiplikation und Division zuerst, dann plus und minus. Klammern noch früher. Tippe nur die Teilrechnung, die jetzt dran ist.'
          : 'Multiplication and division first, then plus and minus. Brackets even earlier. Type only the part that is due now.',
      'trig' => german
          ? 'sin, cos, tan brauchen eine Einheit: Grad oder Bogenmaß. In der Schule fast immer Grad. Die Taste am Taschenrechner musst du selbst prüfen.'
          : 'sin, cos, tan need a unit: degrees or radians. School work is almost always degrees. Check the calculator mode yourself.',
      'derivative' => german
          ? 'Die Ableitung beschreibt die Steigung. Die Potenzregel steht im Tafelwerk: aus x^n wird n·x^(n−1). Einsetzen tust du.'
          : 'The derivative is the slope. The power rule is in the formula book: x^n becomes n·x^(n−1). You substitute.',
      'percent' => german
          ? 'p % von G heißt (p/100)·G. Prozent ist ein Hundertstel. Grundwert, Prozentwert und Prozentsatz nicht vertauschen.'
          : 'p% of G means (p/100)·G. Percent is a hundredth. Do not mix up base, amount, and rate.',
      _ => german
          ? 'Ich erkläre den Weg und den Zusammenhang. Die letzte Zahl oder den Klausursatz formulierst du selbst.'
          : 'I explain the method and the connection. You write the final number or exam sentence yourself.',
    };
  }

  static const all = <GemmaTopic>[
    GemmaTopic(
      id: 'versailles',
      keywords: [
        'versailles',
        'versaille',
        'kriegsschuld',
        'diktat',
        'reparation',
      ],
      titleDe: 'Versailles und die Folgen',
      titleEn: 'Versailles and its consequences',
      bodyDe:
          'Der Versailler Vertrag (1919) beendete den Ersten Weltkrieg. Deutschland musste Gebietsabtretungen, Reparationen und die alleinige Kriegsschuld (Art. 231) akzeptieren. Viele Deutsche empfanden das als Demütigung — „Diktatfrieden“. Das schwächte die Weimarer Republik: rechte und linke Gegner nutzten den Vertrag als Beweis, der Staat sei ungerecht und schwach. Der Zusammenhang zur späteren NS-Propaganda: Hitler versprach, Versailles „zu zerreißen“. Das erklärt die Stimmung, ersetzt aber nicht deine Quellenarbeit.',
      bodyEn:
          'The Treaty of Versailles (1919) ended World War I. Germany accepted territorial losses, reparations, and sole war guilt (Art. 231). Many Germans saw it as a humiliation. That weakened Weimar: opponents used the treaty as proof the state was unjust. Nazi propaganda later promised to tear Versailles up. That is the mood — you still work the sources yourself.',
    ),
    GemmaTopic(
      id: 'weimar',
      keywords: [
        'weimar',
        'inflation',
        'ruhrbesetzung',
        'weltwirtschaftskrise',
        'notverordnung',
      ],
      titleDe: 'Weimar: Krise und Belastung',
      titleEn: 'Weimar: crisis and strain',
      bodyDe:
          'Die Republik startete mit Kriegsniederlage, Versailles und politischer Gewalt. 1923 kamen Ruhrbesetzung und Hyperinflation — Ersparnisse wurden wertlos, das Vertrauen in den Staat sank. Ab 1929 verschärfte die Weltwirtschaftskrise die Arbeitslosigkeit. Mitende der 1920er Jahre regierten oft Präsidialkabinette per Notverordnung (Art. 48). Zusammenhang: wirtschaftliche Not + verächtliche Haltung zur Demokratie + starke Anti-System-Parteien. Wenn deine Aufgabe nach Ursachen für das Scheitern fragt, trenne außenpolitisch, wirtschaftlich und politisch.',
      bodyEn:
          'Weimar began with defeat, Versailles, and political violence. 1923 brought the Ruhr occupation and hyperinflation. From 1929 the Great Depression drove unemployment. Late Weimar often ruled by emergency decree. Link: economic pain + contempt for democracy + anti-system parties. If the task asks why it failed, split foreign, economic, and political causes.',
    ),
    GemmaTopic(
      id: 'ns_aufstieg',
      keywords: [
        'hitler',
        'nsdap',
        'machtergreifung',
        'ermächtigung',
        'gleichschaltung',
        'nationalsozial',
      ],
      titleDe: 'Aufstieg der NSDAP',
      titleEn: 'Rise of the NSDAP',
      bodyDe:
          'Die NSDAP blieb lange eine Randpartei. Erst die Weltwirtschaftskrise, Protest gegen Versailles und das Zerfallen der bürgerlichen Mitte machten sie zur Massenpartei. 1933: Ernennung Hitlers zum Reichskanzler, Reichstagsbrand, Ermächtigungsgesetz, Gleichschaltung. Wichtig: das war kein „plötzlicher Unfall“, sondern ein Zusammenspiel aus Krise, Elitenkalkül und Zerstörung der Verfassung. In der Aufgabe unterscheide Voraussetzungen, Anlass und Folgen — ich schreibe dir die Klausurgliederung nicht fertig.',
      bodyEn:
          'The NSDAP was a fringe party for years. The Depression, anti-Versailles anger, and the collapse of the centre made it a mass party. 1933: Hitler as chancellor, Reichstag fire, Enabling Act, coordination of the state. Not a sudden accident — crisis, elite calculation, and the destruction of the constitution. Separate preconditions, trigger, and consequences in your task.',
    ),
    GemmaTopic(
      id: 'holocaust',
      keywords: [
        'holocaust',
        'shoah',
        'auschwitz',
        'judenverfolgung',
        'nürnberger',
        'nuernberger',
        'pogrom',
      ],
      titleDe: 'Verfolgung und Völkermord',
      titleEn: 'Persecution and genocide',
      bodyDe:
          'Die Verfolgung der Juden war kein spontaner Ausbruch, sondern staatlich geplant: Ausgrenzung, Nürnberger Gesetze, Novemberpogrom 1938, Deportation, Vernichtung. Der Holocaust ist industrieller Völkermord. Wenn eine Quelle oder Karikatur das Thema hat, beschreibe zuerst sachlich, was zu sehen ist, dann die Absicht der Täter oder des Zeichners. Spekuliere nicht verharmlosend. Bei deiner Deutung: Wer handelt, wer wird getroffen, welche Ideologie steckt dahinter?',
      bodyEn:
          'The persecution of Jews was state-planned: exclusion, Nuremberg Laws, the 1938 pogrom, deportation, murder. The Holocaust is industrial genocide. If a source or cartoon treats this, first describe factually what is shown, then the intent. Do not downplay. In your interpretation: who acts, who is targeted, which ideology is behind it?',
    ),
    GemmaTopic(
      id: 'kalter_krieg',
      keywords: [
        'kalter krieg',
        'kaltkrieg',
        'mauer',
        'berliner mauer',
        'teilung',
        'ddr',
        'brd',
        'nato',
        'warschauer',
        'wiedervereinigung',
      ],
      titleDe: 'Teilung, Kalter Krieg, Mauer',
      titleEn: 'Division, Cold War, the Wall',
      bodyDe:
          'Nach 1945 standen sich USA und Sowjetunion als Blöcke gegenüber: Kapitalismus/Demokratie gegen Kommunismus/Planwirtschaft. Deutschland wurde zur Front: 1949 BRD und DDR, 1961 die Mauer, um die Abwanderung aus der DDR zu stoppen. Stellvertreterkonflikte (Korea, Kuba, Vietnam) zeigen, dass „kalt“ nicht friedlich heißt. 1989/90: Reformdruck, Flucht, Mauerfall, Wiedervereinigung. In einer Karikatur sind oft Bär, Uncle Sam, Mauer oder zwei Hälften eines Landes Symbole für diese Blöcke.',
      bodyEn:
          'After 1945 the US and the Soviet Union faced each other as blocs. Germany became the front line: FRG and GDR in 1949, the Wall in 1961 to stop emigration. Proxy wars show that “cold” was not peaceful. 1989/90: pressure, flight, the Wall fell, reunification. In cartoons a bear, Uncle Sam, a wall, or a split country often stand for the blocs.',
    ),
    GemmaTopic(
      id: 'franzoesische_revolution',
      keywords: [
        'französische revolution',
        'franzoesische revolution',
        '1789',
        'bastille',
        'ludwig xvi',
        'absolute monarchie',
        'menschenrechte 1789',
      ],
      titleDe: 'Französische Revolution',
      titleEn: 'French Revolution',
      bodyDe:
          '1789 stürzte das Bürgertum die absolute Monarchie: Steuerlast, Hunger, Aufklärung, ein König, der nicht teilen wollte. Losung Freiheit, Gleichheit, Brüderlichkeit — und bald Terror, Krieg, Napoleon. Zusammenhang: moderne Menschen- und Bürgerrechte entstehen hier, aber die Revolution frisst auch ihre Kinder. Wenn eine Karikatur den König, den dritten Stand oder die Guillotine zeigt, frag: Wer soll belacht oder angeklagt werden?',
      bodyEn:
          'In 1789 the bourgeoisie overthrew absolute monarchy: tax burden, hunger, Enlightenment, a king who would not share. Liberty, equality, fraternity — then terror, war, Napoleon. Modern rights begin here, and the revolution also consumes its children. If a cartoon shows the king, the third estate, or the guillotine, ask: who is being mocked or accused?',
    ),
    GemmaTopic(
      id: 'industrialisierung',
      keywords: [
        'industrialisierung',
        'industrielle revolution',
        'soziale frage',
        'pauperismus',
        'fabrik',
        'arbeiterbewegung',
      ],
      titleDe: 'Industrialisierung und soziale Frage',
      titleEn: 'Industrialisation and the social question',
      bodyDe:
          'Maschinen, Fabriken, Eisenbahn veränderten Arbeit und Massengesellschaft. Reichtum entstand, aber auch Elend: lange Tage, Kinderarbeit, Wohnungsnot — die „soziale Frage“. Daraus wuchsen Arbeiterbewegung, Sozialismus, später Sozialgesetze. In Karikaturen stehen Schornstein, Zahnrad, ausgezehrte Figuren oder ein dicker Fabrikant oft für genau diesen Gegensatz.',
      bodyEn:
          'Machines, factories, and railways changed work and society. Wealth grew, and so did misery: long days, child labour, slums — the “social question”. That fed the labour movement, socialism, later social laws. In cartoons a chimney, a gear, a starved figure, or a fat industrialist often mark that contrast.',
    ),
    GemmaTopic(
      id: 'imperialismus',
      keywords: [
        'imperialismus',
        'kolonial',
        'kolonie',
        'wettlauf um afrika',
        'herero',
      ],
      titleDe: 'Imperialismus',
      titleEn: 'Imperialism',
      bodyDe:
          'Im 19. Jahrhundert teilten europäische Mächte die Welt: Rohstoffe, Absatzmärkte, Machtprestige. Der „Wettlauf um Afrika“ und koloniale Gewalt gehören dazu. Deutschland stieg spät ein und radikalisierte oft. Zusammenhang zur Karikatur: Kuchen, der geteilt wird, eine Landkarte als Beute, unterdrückte Figuren. Frag: Wer schneidet, wer liegt auf dem Tisch?',
      bodyEn:
          'In the 19th century European powers divided the world: resources, markets, prestige. The scramble for Africa and colonial violence belong here. Cartoons often show a cake being sliced, a map as loot, or oppressed figures. Ask: who cuts, who lies on the table?',
    ),
    GemmaTopic(
      id: 'erster_weltkrieg',
      keywords: [
        'erster weltkrieg',
        '1. weltkrieg',
        '1914',
        'schlieffen',
        'allianz',
        'mittelmächte',
        'mittelmaechte',
      ],
      titleDe: 'Erster Weltkrieg',
      titleEn: 'First World War',
      bodyDe:
          'Bündnisse, Wettrüsten, Nationalismus und die Julikrise 1914 führten in einen Industriekrieg. Stellungskrieg, Materialschlachten, totale Mobilisierung. Der Krieg endete 1918 mit der Niederlage der Mittelmächte — und mit Versailles. Wenn deine Aufgabe nach „Ursachen“ fragt, trenne langfristig (Bündnisse, Imperialismus) und kurzfristig (Attentat, Ultimaten).',
      bodyEn:
          'Alliances, arms races, nationalism, and the July 1914 crisis led into industrial war. Trench warfare, total mobilisation. It ended in 1918 with the defeat of the Central Powers — and Versailles. If the task asks for causes, split long-term (alliances, imperialism) and short-term (assassination, ultimata).',
    ),
    GemmaTopic(
      id: 'demokratie',
      keywords: [
        'grundgesetz',
        'gewaltenteilung',
        'demokratie',
        'reichstag',
        'bundesrepublik',
        'wehrhafte',
      ],
      titleDe: 'Demokratie und Grundgesetz',
      titleEn: 'Democracy and the Basic Law',
      bodyDe:
          'Nach 1945 sollte sich Weimar nicht wiederholen: Grundrechte, Gewaltenteilung, wehrhafte Demokratie, starkes Verfassungsgericht. Der Bundestag ist das Parlament, die Regierung braucht eine Mehrheit, Grundrechte binden den Staat. In einer Karikatur zur Politik der Gegenwart frag: Wird Macht kritisiert, ein Recht verteidigt oder eine Partei verspottet?',
      bodyEn:
          'After 1945 Weimar was not to be repeated: basic rights, separation of powers, a militant democracy, a strong court. Parliament, a government that needs a majority, rights that bind the state. In a cartoon about today’s politics ask: is power criticised, a right defended, or a party mocked?',
    ),
    GemmaTopic(
      id: 'karikatur',
      keywords: [
        'karikatur',
        'caricature',
        'cartoon',
        'spottbild',
        'bildsatire',
      ],
      titleDe: 'Karikatur lesen',
      titleEn: 'Reading a caricature',
      bodyDe:
          'Eine Karikatur ist keine Fotografie, sondern Meinung mit Übertreibung. Schule: 1) Beschreibung — Personen, Dinge, Text, Vorder-/Hintergrund. 2) Analyse — Symbole, Verzerrung, wer groß/klein, wer oben/unten. 3) Deutung — historische Lage, Botschaft, wen der Zeichner angreift. 4) Urteil — überzeugend? einseitig? Ich erkläre Symbole und Zusammenhänge, den Schlusssatz der Deutung formulierst du.',
      bodyEn:
          'A caricature is an opinion with exaggeration, not a photo. School method: 1) Describe people, objects, captions. 2) Analyse symbols, distortion, who is big/small. 3) Interpret the historical moment and who is attacked. 4) Judge: convincing? one-sided? I explain symbols and context; you write the final interpretation sentence.',
    ),
    GemmaTopic(
      id: 'quelle',
      keywords: [
        'bildquelle',
        'quelle analys',
        'quellenanalyse',
        'plakat',
        'propaganda',
      ],
      titleDe: 'Bild- und Textquelle',
      titleEn: 'Image and text sources',
      bodyDe:
          'Jede Quelle hat Herkunft, Zeit, Autor, Absicht. Frag: Wer spricht, wann, zu wem, wozu? Ein Plakat will werben oder hetzen, ein Foto kann gestellt sein, eine Rede will überzeugen. Trenn erst den Inhalt (was steht da?) von der Bewertung (was will der Autor?). Den Zusammenhang zur Epoche erkläre ich dir, die Einordnung in deine Leitfrage schreibst du.',
      bodyEn:
          'Every source has origin, time, author, purpose. Who speaks, when, to whom, why? A poster wants to sell or stir, a photo can be staged. Separate content from intent. I explain the era; you fit it to the question in your task.',
    ),
  ];

  static const symbols = <GemmaTopic>[
    GemmaTopic(
      id: 'michel',
      keywords: ['michel', 'deutsche michel'],
      titleDe: 'Symbol: Deutscher Michel',
      titleEn: 'Symbol: German Michel',
      bodyDe:
          'Schlaf- oder Zipfelmütze, oft naiv oder ausgenutzt: steht für „die Deutschen“ als Volk, das zu spät aufwacht oder übervorteilt wird.',
      bodyEn:
          'Nightcap, often naive or exploited: stands for “the Germans” as a people who wake too late or get cheated.',
    ),
    GemmaTopic(
      id: 'uncle_sam',
      keywords: ['uncle sam', 'onkel sam', 'usa-hut', 'stars and stripes'],
      titleDe: 'Symbol: Uncle Sam',
      titleEn: 'Symbol: Uncle Sam',
      bodyDe:
          'Zylinder mit Sternen, Kinnbart: die USA als Macht, oft fordernd oder als Weltpolizist gezeichnet.',
      bodyEn:
          'Starred top hat and goatee: the USA as a power, often demanding or drawn as world police.',
    ),
    GemmaTopic(
      id: 'baer',
      keywords: ['sowjet', 'bär', 'baer', 'hammer und sichel', 'roter stern'],
      titleDe: 'Symbol: Bär / Sowjetunion',
      titleEn: 'Symbol: bear / Soviet Union',
      bodyDe:
          'Der russische oder sowjetische Bär, Hammer und Sichel, roter Stern: kommunistische Großmacht, oft als bedrohlich oder plump gezeichnet.',
      bodyEn:
          'The Russian or Soviet bear, hammer and sickle, red star: communist great power, often drawn as threatening or clumsy.',
    ),
    GemmaTopic(
      id: 'taube',
      keywords: ['friedenstaube', 'olivenzweig', 'taube'],
      titleDe: 'Symbol: Taube',
      titleEn: 'Symbol: dove',
      bodyDe:
          'Taube und Olivenzweig stehen für Frieden. Wird sie zerrissen, im Käfig oder neben Waffen gezeigt, ist die Botschaft meist: Frieden ist bedroht oder heuchlerisch.',
      bodyEn:
          'A dove and olive branch stand for peace. Torn, caged, or next to weapons, the message is usually that peace is threatened or hypocritical.',
    ),
    GemmaTopic(
      id: 'kette',
      keywords: ['kette', 'fessel', 'joch', 'knechtschaft'],
      titleDe: 'Symbol: Kette / Fessel',
      titleEn: 'Symbol: chain',
      bodyDe:
          'Ketten bedeuten Unfreiheit, Schulden, Abhängigkeit. Wer sie sprengt oder wem sie angelegt werden, ist die politische Aussage.',
      bodyEn:
          'Chains mean unfreedom, debt, dependence. Who breaks them — or who is bound — is the political point.',
    ),
    GemmaTopic(
      id: 'waage',
      keywords: ['waage', 'justitia', 'gerechtigkeit'],
      titleDe: 'Symbol: Waage',
      titleEn: 'Symbol: scales',
      bodyDe:
          'Die Waage steht für Gerechtigkeit. Hängt eine Seite schief, wirft der Zeichner einer Seite Parteilichkeit oder Ungleichheit vor.',
      bodyEn:
          'Scales stand for justice. If one side dips, the cartoonist accuses bias or inequality.',
    ),
  ];

  static List<GemmaTopic> matchSymbols(String raw) => [
    for (final topic in symbols)
      if (topic.keywords.any((k) => raw.toLowerCase().contains(k))) topic,
  ];
}
