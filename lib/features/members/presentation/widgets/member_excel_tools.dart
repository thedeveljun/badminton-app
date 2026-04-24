import 'dart:io';
import 'dart:typed_data';

import 'package:downloadsfolder/downloadsfolder.dart' hide Context;
import 'package:excel/excel.dart' hide Border, Context;
import 'package:file_picker/file_picker.dart' hide Context;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart' hide Context;
import 'package:path_provider/path_provider.dart' hide Context;
import 'package:share_plus/share_plus.dart' hide Context;

class ImportedMemberRow {
  final int sourceRowNumber;
  final String name;
  final String gender;
  final String birthDate;
  final String phone;
  final String grade;
  final String address;

  const ImportedMemberRow({
    required this.sourceRowNumber,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.phone,
    required this.grade,
    required this.address,
  });

  String get duplicateKey =>
      '${name.trim()}|${gender.trim()}|${birthDate.trim()}|${phone.trim()}';
}

class ExcelRowError {
  final int rowNumber;
  final String message;

  const ExcelRowError({required this.rowNumber, required this.message});
}

class ExcelImportResult {
  final List<ImportedMemberRow> rows;
  final List<ExcelRowError> errors;

  const ExcelImportResult({required this.rows, required this.errors});
}

class MemberExcelTools extends StatefulWidget {
  final Future<void> Function(List<ImportedMemberRow> rows) onImportRows;

  const MemberExcelTools({super.key, required this.onImportRows});

  @override
  State<MemberExcelTools> createState() => _MemberExcelToolsState();
}

class _MemberExcelToolsState extends State<MemberExcelTools> {
  bool _isUploading = false;
  bool _isDownloading = false;

  File? _lastDownloadedFile;

  static const String _sampleAssetPath = 'assets/excel/회원업로드_샘플.xlsx';

  static const List<String> _headers = ['이름', '성별', '생년월일', '전화번호', '급수', '주소'];

  /// 샘플 파일을 다운로드 폴더로 저장.
  /// assets에 파일이 없으면 코드로 샘플 엑셀을 생성합니다.
  Future<void> _downloadSampleFile() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      Uint8List bytes;
      try {
        final ByteData assetData = await rootBundle.load(_sampleAssetPath);
        bytes = assetData.buffer.asUint8List();
      } catch (_) {
        // assets에 없으면 코드로 생성
        bytes = _buildSampleExcelBytes();
      }

      if (bytes.isEmpty) {
        if (!mounted) return;
        _showErrorDialog('샘플 파일을 만들지 못했습니다.');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/회원업로드_샘플.xlsx');
      await tempFile.writeAsBytes(bytes, flush: true);

      bool? saved;
      try {
        saved = await copyFileIntoDownloadFolder(
          tempFile.path,
          '회원업로드_샘플.xlsx',
        );
      } catch (_) {
        saved = false;
      }

      if (!mounted) return;
      _lastDownloadedFile = tempFile;

      if (saved == true) {
        ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: const Text(
              '샘플 엑셀파일이 다운로드 폴더에 저장되었습니다.',
              style: TextStyle(fontSize: 12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '열기',
              onPressed: _openLastDownloadedFile,
            ),
          ),
        );
      } else {
        // 다운로드 폴더 저장 실패 시 공유로 대체 안내
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: const Text(
              '다운로드 폴더 저장 실패. 공유를 이용해 저장하세요.',
              style: TextStyle(fontSize: 12),
            ),
            action: SnackBarAction(
              label: '공유',
              onPressed: _shareLastDownloadedFile,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('샘플 파일 다운로드 중 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Uint8List _buildSampleExcelBytes() {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, '회원업로드');
    final sheet = excel['회원업로드'];

    // 헤더
    for (int i = 0; i < _headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        _headers[i],
      );
    }

    // 샘플 데이터
    final sampleRows = [
      ['홍길동', '남', '900101', '010-1234-5678', 'B', '서울시 중구'],
      ['김영희', '여', '920505', '010-2345-6789', 'C', '경기도 성남시'],
    ];
    for (int r = 0; r < sampleRows.length; r++) {
      for (int c = 0; c < sampleRows[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          sampleRows[r][c],
        );
      }
    }

    final encoded = excel.encode();
    return encoded == null ? Uint8List(0) : Uint8List.fromList(encoded);
  }

  Future<void> _openLastDownloadedFile() async {
    final file = _lastDownloadedFile;

    if (file == null) {
      if (!mounted) return;
      _showErrorDialog('먼저 샘플 파일을 다운로드해주세요.');
      return;
    }

    if (!await file.exists()) {
      if (!mounted) return;
      _showErrorDialog('열 수 있는 파일을 찾지 못했습니다.');
      return;
    }

    final result = await OpenFilex.open(file.path);

    if (!mounted) return;

    if (result.type != ResultType.done) {
      _showErrorDialog('파일을 열지 못했습니다.\n${result.message}');
    }
  }

  Future<void> _shareLastDownloadedFile() async {
    final file = _lastDownloadedFile;

    if (file == null) {
      if (!mounted) return;
      _showErrorDialog('먼저 샘플 파일을 다운로드해주세요.');
      return;
    }

    if (!await file.exists()) {
      if (!mounted) return;
      _showErrorDialog('공유할 파일을 찾지 못했습니다.');
      return;
    }

    await Share.shareXFiles([XFile(file.path)], text: '회원업로드 샘플 파일입니다.');
  }

  Future<void> _openDownloadFolder() async {
    try {
      await openDownloadFolder();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('다운로드 폴더를 열지 못했습니다.\n$e');
    }
  }

  Future<void> _pickAndImportExcel() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        return;
      }

      final file = picked.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        _showErrorDialog('선택한 파일을 읽을 수 없습니다.');
        return;
      }

      final result = _parseMemberExcel(bytes);

      if (!mounted) return;

      await _showPreviewDialog(result);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('엑셀 업로드 중 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  ExcelImportResult _parseMemberExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      return const ExcelImportResult(
        rows: [],
        errors: [ExcelRowError(rowNumber: 1, message: '엑셀 시트를 찾을 수 없습니다.')],
      );
    }

    final sheet = excel.tables.values.first;

    if (sheet.rows.isEmpty) {
      return const ExcelImportResult(
        rows: [],
        errors: [ExcelRowError(rowNumber: 1, message: '엑셀 파일이 비어 있습니다.')],
      );
    }

    final headerErrors = _validateHeaders(sheet.rows.first);
    if (headerErrors.isNotEmpty) {
      return ExcelImportResult(rows: const [], errors: headerErrors);
    }

    final importedRows = <ImportedMemberRow>[];
    final errors = <ExcelRowError>[];

    for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      final excelRowNumber = rowIndex + 1;

      final values = List<String>.generate(
        _headers.length,
        (index) => index < row.length ? _cellToString(row[index]) : '',
      );

      if (_isEntireRowEmpty(values)) continue;

      try {
        final name = values[0].trim();
        final gender = values[1].trim();
        final birthDate = values[2].trim();
        final rawPhone = values[3].trim();
        final grade = values[4].trim();
        final address = values[5].trim();

        if (name.isEmpty) {
          throw '이름은 필수입니다.';
        }

        if (gender != '남' && gender != '여') {
          throw '성별은 "남" 또는 "여"만 입력 가능합니다.';
        }

        if (!_isValidBirthYYMMDD(birthDate)) {
          throw '생년월일은 YYMMDD 형식의 올바른 날짜여야 합니다.';
        }

        final normalizedPhone = _normalizePhone(rawPhone);
        if (!_isValidPhone(normalizedPhone)) {
          throw '전화번호 형식이 올바르지 않습니다.';
        }

        if (grade.isEmpty) {
          throw '급수는 필수입니다.';
        }

        importedRows.add(
          ImportedMemberRow(
            sourceRowNumber: excelRowNumber,
            name: name,
            gender: gender,
            birthDate: birthDate,
            phone: normalizedPhone,
            grade: grade,
            address: address,
          ),
        );
      } catch (e) {
        errors.add(
          ExcelRowError(rowNumber: excelRowNumber, message: e.toString()),
        );
      }
    }

    return ExcelImportResult(rows: importedRows, errors: errors);
  }

  List<ExcelRowError> _validateHeaders(List<Data?> headerRow) {
    final actualHeaders = headerRow.map(_cellToString).toList();
    final errors = <ExcelRowError>[];

    for (int i = 0; i < _headers.length; i++) {
      final actual = i < actualHeaders.length ? actualHeaders[i].trim() : '';

      if (actual != _headers[i]) {
        errors.add(
          ExcelRowError(
            rowNumber: 1,
            message: '${i + 1}열 헤더는 "${_headers[i]}" 이어야 합니다.',
          ),
        );
      }
    }

    return errors;
  }

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  bool _isEntireRowEmpty(List<String> values) {
    return values.every((e) => e.trim().isEmpty);
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }

    if (digits.length == 10) {
      if (digits.startsWith('02')) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return raw;
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 10 || digits.length == 11;
  }

  bool _isValidBirthYYMMDD(String value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return false;

    final yy = int.parse(value.substring(0, 2));
    final mm = int.parse(value.substring(2, 4));
    final dd = int.parse(value.substring(4, 6));

    final currentYY = DateTime.now().year % 100;
    final fullYear = yy > currentYY ? 1900 + yy : 2000 + yy;

    return _isValidDate(fullYear, mm, dd);
  }

  bool _isValidDate(int year, int month, int day) {
    try {
      final dt = DateTime(year, month, day);
      return dt.year == year && dt.month == month && dt.day == day;
    } catch (_) {
      return false;
    }
  }

  Map<String, int> _buildDuplicateCountMap(List<ImportedMemberRow> rows) {
    final map = <String, int>{};
    for (final row in rows) {
      map[row.duplicateKey] = (map[row.duplicateKey] ?? 0) + 1;
    }
    return map;
  }

  bool _isDuplicateRow(
    ImportedMemberRow row,
    Map<String, int> duplicateCountMap,
  ) {
    return (duplicateCountMap[row.duplicateKey] ?? 0) > 1;
  }

  Future<void> _showPreviewDialog(ExcelImportResult result) async {
    if (!mounted) return;

    final duplicateCountMap = _buildDuplicateCountMap(result.rows);
    final duplicateRows = result.rows
        .where((row) => _isDuplicateRow(row, duplicateCountMap))
        .length;

    final canImport = result.rows.isNotEmpty;

    await showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: const Text(
            '업로드 미리보기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정상 데이터: ${result.rows.length}건',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '중복 표시: $duplicateRows건',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '오류 행: ${result.errors.length}건',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                const Text(
                  '중복 회원은 빨간색 배경으로 표시됩니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB00020),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (result.rows.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD8DEE8),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3F6FA),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    '정상 데이터 미리보기',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                ...result.rows.map((row) {
                                  final isDuplicate = _isDuplicateRow(
                                    row,
                                    duplicateCountMap,
                                  );
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDuplicate
                                          ? const Color(0xFFFFE5E5)
                                          : Colors.white,
                                      border: const Border(
                                        top: BorderSide(
                                          color: Color(0xFFE6EBF2),
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${row.sourceRowNumber}행',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF5F6B7A),
                                              ),
                                            ),
                                            if (isDuplicate) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFD93025,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                ),
                                                child: const Text(
                                                  '중복',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${row.name} (${row.gender})  ${row.birthDate}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '전화번호: ${row.phone}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          '${row.grade}조',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          '주소: ${row.address.isEmpty ? '-' : row.address}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        if (result.errors.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6F6),
                              border: Border.all(
                                color: const Color(0xFFF1C6C6),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '오류 행',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB00020),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...result.errors.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• ${e.rowNumber}행: ${e.message}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: !canImport
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await widget.onImportRows(result.rows);
                      if (!mounted) return;
                      _showImportResultDialog(result, duplicateRows);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F81A7),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                '업로드 진행',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImportResultDialog(ExcelImportResult result, int duplicateRows) {
    if (!mounted) return;
    showDialog(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '엑셀 업로드 결과',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '정상 등록 대상: ${result.rows.length}건',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '중복 표시된 행: $duplicateRows건',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '오류 행: ${result.errors.length}건',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (result.errors.isNotEmpty) ...[
                    const Text(
                      '오류 상세',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• ${e.rowNumber}행: ${e.message}',
                          style: const TextStyle(fontSize: 11, height: 1.2),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      '오류 없이 처리되었습니다.',
                      style: TextStyle(fontSize: 13, height: 1.2),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '오류',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 12, height: 1.25),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: _isDownloading ? null : _downloadSampleFile,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(38, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _isDownloading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '샘플',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 95, 162, 239),
                  ),
                ),
        ),
        TextButton(
          onPressed: _isUploading ? null : _pickAndImportExcel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(38, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '업로드',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 37, 110, 244),
                  ),
                ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'open_downloads') {
              _openDownloadFolder();
            } else if (value == 'open_last_file') {
              _openLastDownloadedFile();
            } else if (value == 'share_last_file') {
              _shareLastDownloadedFile();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'open_last_file',
              child: Text('최근 샘플파일 열기'),
            ),
            PopupMenuItem<String>(
              value: 'share_last_file',
              child: Text('최근 샘플파일 공유'),
            ),
            PopupMenuItem<String>(
              value: 'open_downloads',
              child: Text('다운로드 폴더 열기'),
            ),
          ],
          icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF5F81A7)),
        ),
      ],
    );
  }
}
