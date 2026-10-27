// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

void downloadWebFile({
  required String fileName,
  required String content,
  String mimeType = 'text/html',
}) {
  final bytes = utf8.encode(content);
  downloadWebBinaryFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
}

void downloadWebBinaryFile({
  required String fileName,
  required List<int> bytes,
  String mimeType = 'application/pdf',
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

void printWebDocument(String htmlContent) {
  final bytes = utf8.encode(htmlContent);
  final blob = html.Blob([bytes], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future.delayed(const Duration(seconds: 15), () {
    html.Url.revokeObjectUrl(url);
  });
}

void openWebPdf(List<int> bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future.delayed(const Duration(seconds: 30), () {
    html.Url.revokeObjectUrl(url);
  });
}
