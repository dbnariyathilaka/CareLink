import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/care_type_skill_map.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/status_bar.dart';
import 'patient_payment_detail_screen.dart';
import 'patient_refund_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Payments Screen
//  Figma node: 262-1634 (profile entry point) · 786-992 (this screen)
//  Reads a real `payments` collection that doesn't exist anywhere in this
//  app yet — billing hasn't been built, so this streams empty and shows an
//  honest "no payments yet" state today. Built against the schema proposed
//  for the future billing feature (see PaymentService) so it activates
//  automatically, with no changes needed here, once that collection is
//  real. Nothing on this screen is fabricated/hardcoded sample data.
// ─────────────────────────────────────────────────────────────

enum _SortOrder { newest, oldest, amountHighLow }
enum _DateRangeOption { thisMonth, last3Months, thisYear, custom }

class PatientPaymentsScreen extends StatefulWidget {
  const PatientPaymentsScreen({super.key});

  @override
  State<PatientPaymentsScreen> createState() => _PatientPaymentsScreenState();
}

class _PatientPaymentsScreenState extends State<PatientPaymentsScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color cardBg = Color(0xFFBAADA1);
  static const Color chipBg = Color(0xFFD8CFC0);
  static const Color chipBorder = Color(0xFF06402B);
  static const Color emptyTitle = Color(0xFF462911);
  static const Color emptyBody = Color.fromRGBO(70, 41, 17, 0.67);
  static const Color barPast = Color(0xFF8B653E);
  static const Color barCurrent = Color(0xFF1B3A5C);
  static const Color statusCompletedBg = Color(0xFFB8E0C4);
  static const Color statusCompletedText = Color(0xFF1B5E2C);
  static const Color statusPendingBg = Color(0xFFDCD3C2);
  static const Color statusPendingText = Color(0xFF5A4B37);
  static const Color statusRefundedBg = Color(0xFFE3C79A);
  static const Color statusRefundedText = Color(0xFF6B4A16);
  static const Color statusFailedBg = Color(0xFFF2C6C6);
  static const Color statusFailedText = Color(0xFFB01E1E);
  static const Color failedCardBg = Color(0xFFF3D9D9);

  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<Map<String, dynamic>> _payments = const [];

  late DateTime _selectedMonth; // first-of-month — drives the summary card only

  // Transaction-list filters (Figma node 786:1331 "Filter & sort" sheet) —
  // independent of the summary card's fixed current-month view above.
  _DateRangeOption _dateRange = _DateRangeOption.thisMonth;
  DateTimeRange? _customRange;
  Set<String> _statusFilters = {};
  Set<String> _careTypeFilters = {};
  String? _caregiverFilter; // null = "Any caregiver"
  _SortOrder _sortOrder = _SortOrder.newest;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _sub = PaymentService.streamPaymentsForPatient(uid).listen((docs) {
        if (mounted) setState(() => _payments = docs);
      });
    }
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _createdAt(Map<String, dynamic> p) {
    final ts = p['createdAt'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  bool _isInMonth(Map<String, dynamic> p, DateTime month) {
    final dt = _createdAt(p);
    return dt != null && dt.year == month.year && dt.month == month.month;
  }

  List<Map<String, dynamic>> get _monthPayments =>
      _payments.where((p) => _isInMonth(p, _selectedMonth)).toList();

  /// Resolves the current date-range filter to concrete bounds — used by
  /// the transaction list, independent of the summary card's fixed
  /// current-month view.
  DateTimeRange _resolveDateRange(_DateRangeOption option, DateTimeRange? custom) {
    final now = DateTime.now();
    switch (option) {
      case _DateRangeOption.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _DateRangeOption.last3Months:
        return DateTimeRange(start: DateTime(now.year, now.month - 2, 1), end: now);
      case _DateRangeOption.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case _DateRangeOption.custom:
        return custom ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  /// Every distinct caregiver the patient has actually paid — real names
  /// from their own payment history, not the full platform caregiver list.
  List<String> get _knownCaregivers {
    final names = _payments.map((p) => p['caregiverName'] as String?).whereType<String>().toSet().toList();
    names.sort();
    return names;
  }

  List<Map<String, dynamic>> get _filteredAndSorted {
    final query = _searchController.text.trim().toLowerCase();
    final range = _resolveDateRange(_dateRange, _customRange);
    final rangeEndInclusive = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);

    var list = _payments.where((p) {
      final dt = _createdAt(p);
      if (dt == null || dt.isBefore(range.start) || dt.isAfter(rangeEndInclusive)) return false;
      if (_statusFilters.isNotEmpty && !_statusFilters.contains(p['status'] as String?)) {
        return false;
      }
      if (_careTypeFilters.isNotEmpty && !_careTypeFilters.contains(p['careType'] as String?)) {
        return false;
      }
      if (_caregiverFilter != null && (p['caregiverName'] as String?) != _caregiverFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final name = (p['caregiverName'] as String? ?? '').toLowerCase();
      final txnId = (p['transactionId'] as String? ?? '').toLowerCase();
      final amount = (p['amount'] as num?)?.toString() ?? '';
      return name.contains(query) || txnId.contains(query) || amount.contains(query);
    }).toList();

    list.sort((a, b) {
      switch (_sortOrder) {
        case _SortOrder.newest:
          final at = _createdAt(a);
          final bt = _createdAt(b);
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        case _SortOrder.oldest:
          final at = _createdAt(a);
          final bt = _createdAt(b);
          if (at == null || bt == null) return 0;
          return at.compareTo(bt);
        case _SortOrder.amountHighLow:
          final aAmt = (a['amount'] as num?)?.toDouble() ?? 0;
          final bAmt = (b['amount'] as num?)?.toDouble() ?? 0;
          return bAmt.compareTo(aAmt);
      }
    });
    return list;
  }

  double _sumAmount(Iterable<Map<String, dynamic>> docs) =>
      docs.fold<double>(0, (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0));

  String _formatLkr(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return 'LKR $buffer';
  }

  String _monthShort(DateTime month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month.month - 1];
  }

  String _dayLabel(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Figma node 786:1331 "Filter & sort" — a single sheet covering date
  // range, status (multi-select), care type (multi-select), caregiver, and
  // sort, with a live "Show N payments" preview. Edits a local copy of the
  // filter state so Reset/back-out doesn't touch the committed filters
  // until "Show N payments" is tapped.
  void _showFilterSheet() {
    var draftDateRange = _dateRange;
    var draftCustomRange = _customRange;
    var draftStatuses = Set<String>.from(_statusFilters);
    var draftCareTypes = Set<String>.from(_careTypeFilters);
    var draftCaregiver = _caregiverFilter;
    var draftSort = _sortOrder;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bgCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            int previewCount() {
              final range = _resolveDateRange(draftDateRange, draftCustomRange);
              final rangeEnd = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
              return _payments.where((p) {
                final dt = _createdAt(p);
                if (dt == null || dt.isBefore(range.start) || dt.isAfter(rangeEnd)) return false;
                if (draftStatuses.isNotEmpty && !draftStatuses.contains(p['status'] as String?)) return false;
                if (draftCareTypes.isNotEmpty && !draftCareTypes.contains(p['careType'] as String?)) return false;
                if (draftCaregiver != null && (p['caregiverName'] as String?) != draftCaregiver) return false;
                return true;
              }).length;
            }

            Widget sectionLabel(String text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 18),
                  child: Text(
                    text.toUpperCase(),
                    style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                );

            Widget choiceChip(String label, bool selected, VoidCallback onTap) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2C251D) : Colors.transparent,
                    border: Border.all(color: selected ? const Color(0xFFF5B301) : const Color(0xFF2C251D)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: selected ? const Color(0xFFF5B301) : const Color(0xFF2C251D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: const Color(0xFF6E6F72), borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filter & sort', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 19, fontWeight: FontWeight.w700)),
                          GestureDetector(
                            onTap: () => setSheetState(() {
                              draftDateRange = _DateRangeOption.thisMonth;
                              draftCustomRange = null;
                              draftStatuses = {};
                              draftCareTypes = {};
                              draftCaregiver = null;
                              draftSort = _SortOrder.newest;
                            }),
                            child: const Text('Reset', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      sectionLabel('Date range'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          choiceChip('This month', draftDateRange == _DateRangeOption.thisMonth, () => setSheetState(() => draftDateRange = _DateRangeOption.thisMonth)),
                          choiceChip('Last 3 months', draftDateRange == _DateRangeOption.last3Months, () => setSheetState(() => draftDateRange = _DateRangeOption.last3Months)),
                          choiceChip('This year', draftDateRange == _DateRangeOption.thisYear, () => setSheetState(() => draftDateRange = _DateRangeOption.thisYear)),
                          choiceChip(
                            draftDateRange == _DateRangeOption.custom && draftCustomRange != null
                                ? '${_monthShort(draftCustomRange!.start)} ${draftCustomRange!.start.day} – ${_monthShort(draftCustomRange!.end)} ${draftCustomRange!.end.day}'
                                : 'Custom…',
                            draftDateRange == _DateRangeOption.custom,
                            () async {
                              final picked = await showDateRangePicker(
                                context: sheetCtx,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: draftCustomRange,
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  draftDateRange = _DateRangeOption.custom;
                                  draftCustomRange = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      sectionLabel('Status'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in const ['completed', 'pending', 'failed', 'refunded'])
                            choiceChip(
                              s[0].toUpperCase() + s.substring(1),
                              draftStatuses.contains(s),
                              () => setSheetState(() {
                                if (draftStatuses.contains(s)) {
                                  draftStatuses.remove(s);
                                } else {
                                  draftStatuses.add(s);
                                }
                              }),
                            ),
                        ],
                      ),
                      sectionLabel('Care type'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in careTypeSkillMap.keys)
                            choiceChip(
                              c,
                              draftCareTypes.contains(c),
                              () => setSheetState(() {
                                if (draftCareTypes.contains(c)) {
                                  draftCareTypes.remove(c);
                                } else {
                                  draftCareTypes.add(c);
                                }
                              }),
                            ),
                        ],
                      ),
                      sectionLabel('Caregiver'),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: sheetCtx,
                            backgroundColor: bgCream,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (pickerCtx) => SafeArea(
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: const Text('Any caregiver', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen)),
                                    trailing: draftCaregiver == null ? const Icon(Icons.check_rounded, color: darkGreen) : null,
                                    onTap: () {
                                      setSheetState(() => draftCaregiver = null);
                                      Navigator.pop(pickerCtx);
                                    },
                                  ),
                                  for (final name in _knownCaregivers)
                                    ListTile(
                                      title: Text(name, style: const TextStyle(fontFamily: 'Open Sans', color: darkGreen)),
                                      trailing: draftCaregiver == name ? const Icon(Icons.check_rounded, color: darkGreen) : null,
                                      onTap: () {
                                        setSheetState(() => draftCaregiver = name);
                                        Navigator.pop(pickerCtx);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: chipBorder.withValues(alpha: 0.4))),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: darkGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(draftCaregiver ?? 'Any caregiver', style: const TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 13, fontWeight: FontWeight.w600))),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: darkGreen, size: 18),
                            ],
                          ),
                        ),
                      ),
                      sectionLabel('Sort by'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          choiceChip('Newest', draftSort == _SortOrder.newest, () => setSheetState(() => draftSort = _SortOrder.newest)),
                          choiceChip('Oldest', draftSort == _SortOrder.oldest, () => setSheetState(() => draftSort = _SortOrder.oldest)),
                          choiceChip('Amount', draftSort == _SortOrder.amountHighLow, () => setSheetState(() => draftSort = _SortOrder.amountHighLow)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                _dateRange = draftDateRange;
                                _customRange = draftCustomRange;
                                _statusFilters = draftStatuses;
                                _careTypeFilters = draftCareTypes;
                                _caregiverFilter = draftCaregiver;
                                _sortOrder = draftSort;
                              });
                              Navigator.pop(sheetCtx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Text(
                                'Show ${previewCount()} payment${previewCount() == 1 ? '' : 's'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAndSorted;
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final p in filtered) {
      final dt = _createdAt(p);
      final key = dt != null ? _dayLabel(dt) : 'Unknown date';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Payments',
                    style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildSummaryCard(),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...grouped.entries.expand((entry) => [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: darkGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ...entry.value.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildTransactionCard(p),
                                )),
                          ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _dateRange != _DateRangeOption.thisMonth ||
      _statusFilters.isNotEmpty ||
      _careTypeFilters.isNotEmpty ||
      _caregiverFilter != null ||
      _sortOrder != _SortOrder.newest;

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipBorder.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: darkGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Caregiver, transaction ID or amount',
                hintStyle: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune_rounded, color: darkGreen, size: 20),
                  if (_hasActiveFilters)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFFF5B301), shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final completed = _monthPayments.where((p) => p['status'] == 'completed').toList();
    final refunded = _monthPayments.where((p) => p['status'] == 'refunded').toList();
    final spentTotal = _sumAmount(completed);
    final refundedTotal = _sumAmount(refunded);
    final count = completed.length;
    final avg = count > 0 ? spentTotal / count : 0.0;

    final months = List.generate(5, (i) => DateTime(_selectedMonth.year, _selectedMonth.month - (4 - i), 1));
    final monthTotals = months.map((m) {
      final docs = _payments.where((p) => _isInMonth(p, m) && p['status'] == 'completed');
      return _sumAmount(docs);
    }).toList();
    final maxTotal = monthTotals.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPENT IN ${_monthShort(_selectedMonth).toUpperCase()}',
                style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const Text('Monthly', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatLkr(spentTotal),
            style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF2A241A), fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '$count payment${count == 1 ? '' : 's'} · avg ${_formatLkr(avg)}${refundedTotal > 0 ? ' · ${_formatLkr(refundedTotal)} refunded' : ''}',
            style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final isCurrent = i == 4;
              final height = maxTotal == 0 ? 4.0 : (monthTotals[i] / maxTotal * 44.0).clamp(4.0, 44.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: height,
                    decoration: BoxDecoration(
                      color: isCurrent ? barCurrent : barPast,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_monthShort(months[i]), style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: emptyTitle.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No payments yet',
              style: TextStyle(fontFamily: 'Open Sans', color: emptyTitle, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Your payment history will appear here once billing is set up.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Open Sans', color: emptyBody, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final styles = {
      'completed': (statusCompletedBg, statusCompletedText, 'COMPLETED'),
      'pending': (statusPendingBg, statusPendingText, 'PENDING'),
      'refunded': (statusRefundedBg, statusRefundedText, 'REFUNDED'),
      'failed': (statusFailedBg, statusFailedText, 'FAILED'),
    };
    final style = styles[status] ?? (statusPendingBg, statusPendingText, status.toUpperCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: style.$1, borderRadius: BorderRadius.circular(999)),
      child: Text(style.$3, style: TextStyle(fontFamily: 'Open Sans', color: style.$2, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> p) {
    final status = p['status'] as String? ?? 'pending';
    final name = p['caregiverName'] as String? ?? 'Caregiver';
    final careType = p['careType'] as String? ?? '';
    final bookingId = p['bookingId'] as String? ?? '';
    final txnId = p['transactionId'] as String?;
    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
    final cardLast4 = p['cardLast4'] as String?;
    final failureReason = p['failureReason'] as String?;
    final refundEtaLabel = p['refundEtaLabel'] as String?;

    final subtitleParts = [
      if (careType.isNotEmpty) careType,
      if (bookingId.isNotEmpty) bookingId,
      if (status == 'completed' && txnId != null) 'TXN-$txnId',
      if (status == 'failed') 'no-show',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status == 'failed' ? failedCardBg : cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Color(0xFF06402B), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initialsFor(name), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'failed' ? 'Payment failed' : name,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: status == 'failed' ? statusFailedText : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status == 'failed' && failureReason != null
                          ? '$failureReason${bookingId.isNotEmpty ? ' · $bookingId' : ''}'
                          : subtitleParts.join(' · '),
                      style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatLkr(amount),
                    style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (cardLast4 != null) ...[
                    const SizedBox(height: 2),
                    Text('•• $cardLast4', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 10)),
                  ],
                ],
              ),
            ],
          ),
          if (status == 'refunded') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF2C251D), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.autorenew_rounded, color: Color(0xFFE8A94A), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Refund processing${refundEtaLabel != null ? ' · $refundEtaLabel' : ''}',
                      style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusPill(status),
              if (status == 'completed')
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PatientPaymentDetailScreen(payment: p)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View booking', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(width: 3),
                      Icon(Icons.open_in_new_rounded, color: Color(0xFF1B5E2C), size: 12),
                    ],
                  ),
                )
              else if (status == 'refunded')
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PatientRefundDetailScreen(payment: p)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Track refund', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6B4A16), fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF6B4A16), size: 14),
                    ],
                  ),
                )
              else if (status == 'failed')
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Retrying a payment isn\'t available yet.'), duration: Duration(seconds: 2)),
                  ),
                  child: const Text('Retry', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFFB01E1E), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
