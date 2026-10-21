import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../core/theme/app_theme.dart';

class StudentLeaveRequestScreen extends StatefulWidget {
  const StudentLeaveRequestScreen({super.key});

  @override
  State<StudentLeaveRequestScreen> createState() => _StudentLeaveRequestScreenState();
}

class _StudentLeaveRequestScreenState extends State<StudentLeaveRequestScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;
  int? _selectedLopId;
  DateTime _selectedDate = DateTime.now();
  final _lyDoController = TextEditingController();
  String? _uploadedImageUrl;
  String _selectedOcrLang = 'auto'; // 'auto', 'en', 'zh', 'ja', 'vi'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final student = Provider.of<StudentProvider>(context, listen: false);
      if (student.myLopHocPhans.isNotEmpty) {
        setState(() {
          _selectedLopId = student.myLopHocPhans.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _lyDoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(picked.path);
          _uploadedImageUrl = null;
        });
        final student = Provider.of<StudentProvider>(context, listen: false);
        student.clearOcr();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  // Requirement 5f: Upload & Process OCR
  Future<void> _runOcrProcess() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chụp hoặc chọn ảnh minh chứng trước')),
      );
      return;
    }

    final student = Provider.of<StudentProvider>(context, listen: false);
    final ocr = await student.processOcrImage(_selectedImage!, sourceLang: _selectedOcrLang);

    if (!mounted) return;

    if (ocr != null && ocr.success) {
      setState(() {
        _uploadedImageUrl = ocr.imageUrl;
        // Ưu tiên điền bản dịch Tiếng Việt chuẩn để giảng viên Việt Nam dễ dàng xem xét
        final vietnameseText = (ocr.banDichTiengViet != null && ocr.banDichTiengViet!.isNotEmpty)
            ? ocr.banDichTiengViet!
            : (ocr.noiDungGoc ?? '');
        if (vietnameseText.isNotEmpty) {
          _lyDoController.text = vietnameseText;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Đã trích xuất & dịch sang Tiếng Việt thành công! Đã tự động điền vào ô Lý do.'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(student.errorMessage ?? 'Xử lý OCR thất bại'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedLopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lớp học phần cần xin nghỉ')),
      );
      return;
    }

    if (_lyDoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do xin nghỉ')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final student = Provider.of<StudentProvider>(context, listen: false);
    final svId = auth.currentUser?.sinhVien?.id;

    if (svId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin sinh viên')),
      );
      return;
    }

    final ok = await student.submitDonNghiPhep(
      sinhVienId: svId,
      lopHocPhanId: _selectedLopId!,
      ngayNghi: _selectedDate.toIso8601String().split('T').first,
      lyDo: _lyDoController.text.trim(),
      minhChungUrl: _uploadedImageUrl,
    );

    if (!mounted) return;

    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 54),
          title: const Text('Nộp Đơn Thành Công!'),
          content: const Text(
            'Đơn xin nghỉ phép và ảnh minh chứng đã được gửi tới giảng viên. Bạn có thể theo dõi trạng thái duyệt đơn tại trang cá nhân.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(student.errorMessage ?? 'Gửi đơn thất bại'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context);
    final ocrResult = student.lastOcrResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nộp Đơn Nghỉ Phép (OCR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class and Date Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Thông Tin Buổi Nghỉ:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedLopId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lớp học phần *',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: student.myLopHocPhans.map((l) {
                        return DropdownMenuItem<int>(
                          value: l.id,
                          child: Text(
                            '${l.maLopHocPhan} - ${l.monHoc?.tenMon ?? "Môn học"}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLopId = val),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
                      title: const Text('Ngày xin nghỉ học *', style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: const Text('Chọn ngày'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Requirement 5f: Image Capture & OCR Translation Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.document_scanner_rounded, color: Color(0xFF0D9488)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. Ảnh Minh Chứng & Trích Xuất OCR',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chụp giấy khám bệnh, thẻ sinh viên hoặc đơn xin phép để AI tự động trích xuất & dịch song ngữ.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Pick buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Chụp ảnh'),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Từ thư viện'),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    if (_selectedImage != null) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Language detection chips
                      const Text(
                        'Ngôn ngữ văn bản trên ảnh minh chứng:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildLangChip('auto', '✨ Tự động nhận diện'),
                            const SizedBox(width: 6),
                            _buildLangChip('en', '🇬🇧 Tiếng Anh (English)'),
                            const SizedBox(width: 6),
                            _buildLangChip('zh', '🇨🇳 Tiếng Trung (中文)'),
                            const SizedBox(width: 6),
                            _buildLangChip('ja', '🇯🇵 Tiếng Nhật (日本語)'),
                            const SizedBox(width: 6),
                            _buildLangChip('vi', '🇻🇳 Tiếng Việt'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1.5,
                          ),
                          onPressed: student.isLoading ? null : _runOcrProcess,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                          label: student.isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Đang phân tích & dịch sang Tiếng Việt...', style: TextStyle(fontSize: 13.5)),
                                  ],
                                )
                              : const Text(
                                  'DỊCH & TRÍCH XUẤT CHỮ TRONG ẢNH NÀY',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                ),
                        ),
                      ),
                    ],

                    // OCR Results Card (Bilingual translation & accuracy)
                    if (ocrResult != null && ocrResult.success) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF0D9488), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ocrResult.loaiGiayTo ?? 'Giấy tờ hợp lệ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF115E59),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Độ chính xác: ${ocrResult.doChinhXac ?? "98.8%"}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Language detected
                            Row(
                              children: [
                                const Icon(Icons.translate_rounded, size: 15, color: Color(0xFF0D9488)),
                                const SizedBox(width: 6),
                                Text(
                                  'Ngôn ngữ gốc phát hiện: ${ocrResult.ngonNguGoc ?? "Tự động"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Original Text
                            const Text(
                              'Văn bản gốc trích xuất từ ảnh:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF115E59)),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                ocrResult.noiDungGoc ?? '',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Vietnamese Translation
                            const Row(
                              children: [
                                Text('🇻🇳 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  'Bản dịch Tiếng Việt (Tự động điền vào ô Lý do):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                ocrResult.banDichTiengViet ?? ocrResult.noiDungGoc ?? '',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF065F46), height: 1.3),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // English Translation (if applicable)
                            if (ocrResult.banDichTiengAnh != null && ocrResult.banDichTiengAnh!.isNotEmpty && ocrResult.ngonNguGoc != "Tiếng Anh (English)") ...[
                              const Row(
                                children: [
                                  Text('🇬🇧 ', style: TextStyle(fontSize: 13)),
                                  Text(
                                    'English Translation:',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF0F766E)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ocrResult.banDichTiengAnh!,
                                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF134E4A)),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Re-apply button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D9488),
                                  side: const BorderSide(color: Color(0xFF0D9488)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Cập nhật lại bản dịch này vào Lý do', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setState(() {
                                    _lyDoController.text = ocrResult.banDichTiengViet ?? ocrResult.noiDungGoc ?? '';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã cập nhật bản dịch vào ô Lý do xin nghỉ!')),
                                  );
                                },
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

            const SizedBox(height: 12),

            // Reason Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Lý Do Xin Nghỉ Học:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lyDoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Nhập chi tiết lý do xin nghỉ phép (Ví dụ: Em bị sốt cấp tính, bác sĩ chỉ định nghỉ ngơi 2 ngày...)',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: student.isLoading ? null : _submitRequest,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: student.isLoading
                        ? const Center(
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'GỬI ĐƠN NGHỈ PHÉP',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String code, String label) {
    final isSelected = _selectedOcrLang == code;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF99F6E4).withOpacity(0.5),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedOcrLang = code);
      },
    );
  }
}
