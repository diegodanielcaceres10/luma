import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';

// Print-friendly colors, not the dark theme ones.
const kPdfTextPrimary = PdfColor.fromInt(0xFF111827);
const kPdfTextSecondary = PdfColor.fromInt(0xFF6B7280);
const kPdfBorder = PdfColor.fromInt(0xFFE5E7EB);
const kPdfCardFill = PdfColor.fromInt(0xFFF9FAFB);

// Darker than AppColors.authTransfer, which is too light on white paper.
const kPdfTransferColor = PdfColor.fromInt(0xFF4A6FA5);

PdfColor pdfColor(Color color) => PdfColor.fromInt(color.toARGB32());
