import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../data/staged_draft_repository.dart';
import '../../models/staged_transaction_draft.dart';

class PdfUploadState {
  final bool isUploading;
  final String? error;
  final List<StagedTransactionDraft>? lastExtracted;

  PdfUploadState({
    this.isUploading = false,
    this.error,
    this.lastExtracted,
  });

  PdfUploadState copyWith({
    bool? isUploading,
    String? error,
    List<StagedTransactionDraft>? lastExtracted,
  }) {
    return PdfUploadState(
      isUploading: isUploading ?? this.isUploading,
      error: error,
      lastExtracted: lastExtracted ?? this.lastExtracted,
    );
  }
}

class PdfUploadNotifier extends StateNotifier<PdfUploadState> {
  PdfUploadNotifier() : super(PdfUploadState());

  Future<void> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;
    final filePath = kIsWeb ? null : file.path;
    final fileBytes = file.bytes;

    state = state.copyWith(isUploading: true, error: null);

    try {
      final res = await ApiClient.uploadFile(
        '/upload-pdf',
        fieldName: 'file',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: file.name,
      );
      ApiClient.ensureSuccess(res, fallbackMessage: 'Upload failed');

      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : [];
      final drafts = StagedTransactionDraft.fromUploadResponse(decoded);

      if (drafts.isNotEmpty) {
        await StagedDraftRepository.upsertDrafts(drafts);
      }

      state = state.copyWith(isUploading: false, lastExtracted: drafts);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }
}

final pdfUploadProvider = StateNotifierProvider<PdfUploadNotifier, PdfUploadState>((ref) {
  return PdfUploadNotifier();
});
