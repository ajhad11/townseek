import 'dart:io';

void main() async {
  final file = File('lib/screens/business_edit_page.dart');
  var text = await file.readAsString();

  // 1. Replace the AppBar inside build method
  text = text.replaceFirst(RegExp(r'appBar: AppBar\(.*?\),\s+body: Stack\(', dotAll: true), 'body: Stack(');

  final scrollPattern = r'''SafeArea\(
            child: SingleChildScrollView\(
              padding: const EdgeInsets\.all\(20\.0\),
              child: Form\(
                key: _formKey,
                child: Column\(
                  crossAxisAlignment: CrossAxisAlignment\.start,
                  children: \[''';
                  
  final newScroll = '''CustomScrollView(
            slivers: [
              _buildPremiumHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.info_outline, color: Color(0xFF2962FF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 20),''';
  
  text = text.replaceAll(RegExp(scrollPattern), newScroll);

  // Note: Dart replaces using the literal string unless RegExp is used.
  
  // Boundary 1: --- 2. Contact & Location ---
  text = text.replaceAll('// --- 2. Contact & Location ---', '''                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Contact & Location Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.location_on_outlined, color: Color(0xFF2962FF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text("Contact & Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 20),''');

  // Boundary 2: --- 3. Tags Selection ---
  text = text.replaceAll('// --- 3. Tags Selection ---', '''                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Tags Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.sell_outlined, color: Color(0xFF2962FF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text("Search Tags", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 20),''');

  // Boundary 4: Remove 'Shop Image' completely
  text = text.replaceFirst(RegExp(r'// --- 4\. Shop Image ---.*?const SizedBox\(height: 24\),', dotAll: true), '');

  // Boundary 5: --- 5. Opening & Closing Time ---
  text = text.replaceAll('// --- 5. Opening & Closing Time ---', '''                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Business Hours Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [''');

  // Doctor section fix (it sits out of standard structure usually, but we have the wrapper ready)
  text = text.replaceFirst(RegExp(r'// Submit Button.*?SizedBox\(.*?\),\s*\]\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*,', dotAll: true), 
  '''                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),''');

  // Background color update
  text = text.replaceAll('backgroundColor: Colors.white,', 'backgroundColor: const Color(0xFFF8F9FA),');

  // Stack ending fix
  text = text.replaceFirst(RegExp(r'if \(_isLoading\)\s*Container\(\s*color: Colors\.black\.withValues\(alpha: 0\.3\),\s*child: const Center\(child: CircularProgressIndicator\(\)\),\s*\),\s*\]\s*,\s*\)'), 
  '''if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )''');

  // Add the _buildPremiumHeader method before _buildLabel
  final headerMethod = '''  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2962FF),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A47CC), Color(0xFF2962FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            image: _selectedImage != null
                                ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                : (_existingImageUrl != null)
                                    ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                                    : null,
                          ),
                          child: _selectedImage == null && _existingImageUrl == null
                            ? const Icon(Icons.store, color: Color(0xFF2962FF), size: 40) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2962FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shopToEdit != null ? (widget.shopToEdit?['name'] ?? 'Your Business') : 'Add Establishment',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Configure Profile & Settings',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {''';

  text = text.replaceAll("  Widget _buildLabel(String label) {", headerMethod);

  // General text edits
  text = text.replaceAll("'Add Business'", "'Save Changes'");

  await file.writeAsString(text);
}
