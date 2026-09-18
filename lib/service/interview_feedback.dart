class InterviewFeedback {
  const InterviewFeedback({
    required this.wordCount,
    required this.lengthLabel,
    required this.toneLabel,
    required this.tips,
    required this.minimum,
    required this.maximum,
  });
  final int wordCount, minimum, maximum;
  final String lengthLabel, toneLabel;
  final List<String> tips;

  static InterviewFeedback analyse(String text, String prompt) {
    final trimmed = text.trim();
    final count = trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    final brief = prompt == 'introduction' || prompt == 'motivation';
    final minimum = brief ? 60 : 100;
    final maximum = brief ? 160 : 250;
    final tips = <String>[];
    if (count == 0) {
      return InterviewFeedback(
        wordCount: 0,
        minimum: minimum,
        maximum: maximum,
        lengthLabel: 'Start your answer',
        toneLabel: 'Not assessed yet',
        tips: [
          'Write a draft to receive length, tone and clarity suggestions.',
        ],
      );
    }
    final length = count < minimum
        ? 'Short answer'
        : count > maximum
        ? 'Long answer'
        : 'Within the suggested length';
    if (count < minimum) {
      tips.add(
        'Add a specific example and explain your contribution. Aim for roughly $minimum–$maximum words for this prompt.',
      );
    } else if (count > maximum) {
      tips.add(
        'Trim repeated points and background detail. Keep your strongest example and aim for roughly $minimum–$maximum words.',
      );
    } else {
      tips.add(
        'Your answer is within the suggested length. Read it aloud to check that it feels natural.',
      );
    }
    const informal = {
      'gonna': 'going to',
      'wanna': 'want to',
      'kinda': 'somewhat',
      'sorta': 'somewhat',
      'dunno': 'do not know',
      'lol': 'omit this abbreviation',
      'btw': 'by the way',
      'u': 'you',
      'ur': 'your',
    };
    final found = informal.entries
        .where(
          (e) => RegExp('\\b${e.key}\\b', caseSensitive: false).hasMatch(text),
        )
        .toList();
    final stiff = RegExp(
      r'\b(hereby|aforementioned|henceforth|herewith)\b',
      caseSensitive: false,
    ).allMatches(text).map((m) => m.group(0)!).toSet();
    String tone = 'No obvious informal wording found';
    if (found.isNotEmpty) {
      tone = 'Some informal wording';
      tips.add(
        'For a more professional tone: ${found.take(3).map((e) => '“${e.key}” → ${e.value}').join('; ')}.',
      );
    }
    if (stiff.isNotEmpty) {
      tone = found.isEmpty
          ? 'Some overly formal wording'
          : 'Mixed formal and informal wording';
      tips.add(
        'Simplify “${stiff.join('”, “')}”. Use plain language that sounds natural when spoken.',
      );
    }
    if (found.isEmpty && stiff.isEmpty) {
      tips.add(
        'Keep the tone professional but conversational. Everyday contractions such as “I’m” are fine.',
      );
    }
    final sentences = trimmed
        .split(RegExp(r'[.!?\n]+'))
        .where((s) => s.trim().isNotEmpty);
    if (sentences.any((s) => s.trim().split(RegExp(r'\s+')).length > 30)) {
      tips.add(
        'At least one sentence exceeds 30 words. Split it into shorter sentences so your main point is easier to follow.',
      );
    }
    if (!brief) {
      if (!RegExp(
        r'\bI\s+(?:\w+\s+){0,2}(led|built|created|organised|organized|tested|improved|helped|resolved|designed|coordinated|developed|analysed|analyzed)\b',
        caseSensitive: false,
      ).hasMatch(text)) {
        tips.add(
          'Make your own action clear: for example, “I tested…” or “I organised…”. Describe what you actually did.',
        );
      }
      if (!RegExp(
        r'\b(result|outcome|learned|learnt|improved|reduced|increased|achieved|completed|resolved)\b|\d',
        caseSensitive: false,
      ).hasMatch(text)) {
        tips.add(
          'Consider adding the result or what you learned. Use a truthful concrete outcome; numbers are optional.',
        );
      }
    } else if (prompt == 'motivation') {
      tips.add(
        'Check that your reasons connect to this role and that you support a relevant strength with an example.',
      );
    } else {
      tips.add(
        'Connect your current studies or experience, one achievement and your next career goal.',
      );
    }
    return InterviewFeedback(
      wordCount: count,
      minimum: minimum,
      maximum: maximum,
      lengthLabel: length,
      toneLabel: tone,
      tips: tips,
    );
  }
}
