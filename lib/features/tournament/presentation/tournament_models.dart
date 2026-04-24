import 'dart:math';
import 'package:flutter/material.dart';
import '../../members/domain/models/member_item.dart';

int tournamentAge(MemberItem m) {
  if (m.birth.length < 6) return 0;
  final yy = int.tryParse(m.birth.substring(0, 2)) ?? 0;
  return DateTime.now().year - (yy >= 30 ? 1900 + yy : 2000 + yy);
}

enum RoundType {
  same('동일급수', 'AA↔AA  BB↔BB  CC↔CC  DD↔DD', Color(0xFF9C6BA0)),
  balanced('균형급수', 'AD↔BC  BB↔AC  CC↔BD', Color(0xFF6AAE78));

  final String label;
  final String desc;
  final Color color;
  const RoundType(this.label, this.desc, this.color);
}

class TournamentTeam {
  final MemberItem? p1;
  final MemberItem? p2;
  const TournamentTeam(this.p1, this.p2);
  bool get isBye => p1 == null || p2 == null;
  double get avgAge {
    final ages = [
      if (p1 != null) tournamentAge(p1!),
      if (p2 != null) tournamentAge(p2!),
    ];
    return ages.isEmpty ? 0 : ages.reduce((a, b) => a + b) / ages.length;
  }

  List<String> get playerIds => [
    if (p1 != null) p1!.id,
    if (p2 != null) p2!.id,
  ];
}

class TournamentMatch {
  final RoundType roundType;
  final int courtNo;
  final TournamentTeam teamA;
  final TournamentTeam teamB;
  const TournamentMatch({
    required this.roundType,
    required this.courtNo,
    required this.teamA,
    required this.teamB,
  });
  Set<String> get playerIds => {...teamA.playerIds, ...teamB.playerIds};
}

class TournamentResult {
  final List<TournamentMatch> matches;
  final String? warningMessage;
  const TournamentResult({required this.matches, this.warningMessage});
}

class TournamentEngine {
  final List<MemberItem> players;
  final List<RoundType> rounds;
  final int courts;
  final int gamesPerPlayer;
  final Random _rng = Random();

  static const _gradeOrder = ['A', 'B', 'C', 'D', '초심'];

  TournamentEngine(this.players, this.rounds, this.courts, this.gamesPerPlayer);

  List<TournamentMatch> generate() => generateWithWarning().matches;

  TournamentResult generateWithWarning() {
    final allCandidates = <TournamentMatch>[];
    String? warning;

    for (int g = 0; g < gamesPerPlayer; g++) {
      final pool = <String, List<MemberItem>>{};
      for (final m in players) {
        pool.putIfAbsent(m.grade, () => []).add(m);
      }
      pool.forEach((_, list) => list.shuffle(_rng));

      final warnings = <String>[];

      // 1) 동일급수 최대 매칭
      final sameMatches = _buildSameMaximum(pool, warnings);
      allCandidates.addAll(sameMatches);

      // 2) 남은 인원으로 균형급수
      final remaining = <MemberItem>[];
      for (final grade in _gradeOrder) {
        remaining.addAll(pool[grade] ?? []);
      }
      if (remaining.length >= 4) {
        allCandidates.addAll(_buildBalancedFromPool(remaining, pool));
      } else if (remaining.isNotEmpty) {
        warnings.add('균형급수 잔여 ${remaining.length}명 (4명 미만)');
      }

      if (warnings.isNotEmpty) {
        warning = '⚠️ ${g + 1}라운드:\n${warnings.join('\n')}';
      }
    }

    // 3) 휴식시간 최대화 스케줄링
    final scheduled = _scheduleWithRest(allCandidates);
    return TournamentResult(matches: scheduled, warningMessage: warning);
  }

  /// 휴식시간 최대화 스케줄링
  List<TournamentMatch> _scheduleWithRest(List<TournamentMatch> candidates) {
    if (candidates.isEmpty) return [];

    final result = <TournamentMatch>[];
    final remaining = List<TournamentMatch>.from(candidates);

    // 선수별 마지막 출전 슬롯 (-999 = 아직 미출전)
    final lastPlayed = <String, int>{};
    int slot = 0;

    while (remaining.isNotEmpty) {
      // 직전 슬롯 출전 선수 (현재 진행 중)
      final currentlyPlaying = <String>{};
      final slotStart = (slot - 1) * courts;
      for (
        int i = slotStart;
        i < slotStart + courts && i < result.length;
        i++
      ) {
        if (i >= 0) currentlyPlaying.addAll(result[i].playerIds);
      }

      // 직직전 슬롯 출전 선수
      final recentlyPlayed = <String>{};
      final slot2Start = (slot - 2) * courts;
      for (
        int i = slot2Start;
        i < slot2Start + courts && i < result.length;
        i++
      ) {
        if (i >= 0) recentlyPlayed.addAll(result[i].playerIds);
      }

      final usedInSlot = <String>{};
      int assigned = 0;

      for (int c = 0; c < courts && remaining.isNotEmpty; c++) {
        TournamentMatch? best;
        double bestScore = double.infinity;

        for (final match in remaining) {
          final ids = match.playerIds;

          // 이번 슬롯에 이미 배정된 선수 포함이면 스킵
          if (ids.any((id) => usedInSlot.contains(id))) continue;

          double score = 0;

          // 현재 진행 중인 선수 페널티 (최우선 회피)
          final conflict1 = ids
              .where((id) => currentlyPlaying.contains(id))
              .length;
          score += conflict1 * 10000;

          // 직직전 출전 선수 페널티
          final conflict2 = ids
              .where((id) => recentlyPlayed.contains(id))
              .length;
          score += conflict2 * 1000;

          // 마지막 출전이 오래된 선수 우선 (낮을수록 좋음)
          double totalLast = 0;
          for (final id in ids) {
            totalLast += lastPlayed[id] ?? -9999;
          }
          score += totalLast / ids.length;

          if (score < bestScore) {
            bestScore = score;
            best = match;
          }
        }

        if (best != null) {
          result.add(
            TournamentMatch(
              roundType: best.roundType,
              courtNo: c + 1,
              teamA: best.teamA,
              teamB: best.teamB,
            ),
          );
          for (final id in best.playerIds) {
            lastPlayed[id] = slot;
            usedInSlot.add(id);
          }
          remaining.remove(best);
          assigned++;
        }
      }

      // 무한루프 방지: 아무것도 배정 못하면 강제 배정
      if (assigned == 0 && remaining.isNotEmpty) {
        for (int c = 0; c < courts && remaining.isNotEmpty; c++) {
          final m = remaining.removeAt(0);
          result.add(
            TournamentMatch(
              roundType: m.roundType,
              courtNo: c + 1,
              teamA: m.teamA,
              teamB: m.teamB,
            ),
          );
        }
      }

      slot++;
    }

    return result;
  }

  List<TournamentMatch> _buildSameMaximum(
    Map<String, List<MemberItem>> pool,
    List<String> warnings,
  ) {
    final matches = <TournamentMatch>[];

    for (final grade in _gradeOrder) {
      final list = List<MemberItem>.from(pool[grade] ?? []);
      if (list.isEmpty) continue;

      if (list.length < 4) {
        final borrowed = _borrowFromNextGrade(grade, 4 - list.length, pool);
        list.addAll(borrowed);
      }
      if (list.length < 4) continue;

      list.sort((a, b) => tournamentAge(a) - tournamentAge(b));

      final teams = <TournamentTeam>[];
      for (int i = 0; i + 1 < list.length; i += 2) {
        teams.add(TournamentTeam(list[i], list[i + 1]));
      }

      final matchable = teams.length % 2 == 0
          ? teams
          : teams.sublist(0, teams.length - 1);

      final used = <String>{};
      for (int i = 0; i + 1 < matchable.length; i += 2) {
        final tA = matchable[i];
        final tB = matchable[i + 1];
        matches.add(
          TournamentMatch(
            roundType: RoundType.same,
            courtNo: 0,
            teamA: tA,
            teamB: tB,
          ),
        );
        for (final id in [...tA.playerIds, ...tB.playerIds]) {
          used.add(id);
        }
      }

      for (final g in _gradeOrder) {
        pool[g]?.removeWhere((m) => used.contains(m.id));
      }
    }

    return matches;
  }

  List<MemberItem> _borrowFromNextGrade(
    String currentGrade,
    int needed,
    Map<String, List<MemberItem>> pool,
  ) {
    final borrowed = <MemberItem>[];
    final currentIdx = _gradeOrder.indexOf(currentGrade);

    for (
      int delta = 1;
      delta < _gradeOrder.length && borrowed.length < needed;
      delta++
    ) {
      final nextIdx = currentIdx + delta;
      if (nextIdx >= _gradeOrder.length) break;

      final nextList = pool[_gradeOrder[nextIdx]] ?? [];
      if (nextList.isEmpty) continue;

      final currentList = pool[currentGrade] ?? [];
      final refAge = currentList.isNotEmpty
          ? currentList.map(tournamentAge).reduce((a, b) => a + b) /
                currentList.length
          : 0.0;

      nextList.sort(
        (a, b) => (tournamentAge(a) - refAge).abs().compareTo(
          (tournamentAge(b) - refAge).abs(),
        ),
      );

      while (nextList.isNotEmpty && borrowed.length < needed) {
        borrowed.add(nextList.removeAt(0));
      }
    }
    return borrowed;
  }

  List<TournamentMatch> _buildBalancedFromPool(
    List<MemberItem> remaining,
    Map<String, List<MemberItem>> pool,
  ) {
    final matches = <TournamentMatch>[];

    final a = List<MemberItem>.from(pool['A'] ?? []);
    final b = List<MemberItem>.from(pool['B'] ?? []);
    final c = List<MemberItem>.from(pool['C'] ?? []);
    final d = List<MemberItem>.from(pool['D'] ?? []);

    final teamsAD = _crossPair(a, d);
    final teamsBC = _crossPair(b, c);
    final adVsBC = _pairTeams(teamsAD, teamsBC, RoundType.balanced);
    matches.addAll(adVsBC);

    final used = <String>{};
    for (final m in adVsBC) used.addAll(m.playerIds);

    final leftover = remaining.where((m) => !used.contains(m.id)).toList()
      ..sort((x, y) {
        final ai = _gradeOrder.indexOf(x.grade);
        final bi = _gradeOrder.indexOf(y.grade);
        if (ai != bi) return ai - bi;
        return tournamentAge(x) - tournamentAge(y);
      });

    while (leftover.length >= 4) {
      final group = leftover.sublist(0, 4);
      leftover.removeRange(0, 4);
      matches.add(
        TournamentMatch(
          roundType: RoundType.balanced,
          courtNo: 0,
          teamA: TournamentTeam(group[0], group[3]),
          teamB: TournamentTeam(group[1], group[2]),
        ),
      );
    }

    return matches;
  }

  List<TournamentTeam> _crossPair(List<MemberItem> l1, List<MemberItem> l2) {
    final teams = <TournamentTeam>[];
    final used = <String>{};
    for (final p1 in l1) {
      MemberItem? best;
      int bestDiff = 9999;
      for (final p2 in l2) {
        if (used.contains(p2.id)) continue;
        final diff = (tournamentAge(p1) - tournamentAge(p2)).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          best = p2;
        }
      }
      if (best != null) {
        teams.add(TournamentTeam(p1, best));
        used.add(best.id);
      }
    }
    return teams;
  }

  List<TournamentMatch> _pairTeams(
    List<TournamentTeam> listA,
    List<TournamentTeam> listB,
    RoundType rt,
  ) {
    final matches = <TournamentMatch>[];
    final usedB = <int>{};
    for (final tA in listA) {
      double best = double.infinity;
      int bestIdx = -1;
      for (int j = 0; j < listB.length; j++) {
        if (usedB.contains(j)) continue;
        final diff = (tA.avgAge - listB[j].avgAge).abs();
        if (diff < best) {
          best = diff;
          bestIdx = j;
        }
      }
      if (bestIdx != -1) {
        matches.add(
          TournamentMatch(
            roundType: rt,
            courtNo: 0,
            teamA: tA,
            teamB: listB[bestIdx],
          ),
        );
        usedB.add(bestIdx);
      }
    }
    return matches;
  }
}
