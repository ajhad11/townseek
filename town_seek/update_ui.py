import re

with open('lib/screens/business_edit_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace the AppBar inside build method
appbar_pattern = r'appBar: AppBar\(.*?\),\s+body: Stack\('
appbar_replacement = """body: Stack("""
text = re.sub(appbar_pattern, appbar_replacement, text, flags=re.DOTALL)

# 2. Convert SingleChildScrollView down to the Column
scroll_pattern = r'SafeArea\(\s*child: SingleChildScrollView\(\s*padding: const EdgeInsets\.all\(20\.0\),\s*child: Form\(\s*key: _formKey,\s*child: Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \['

new_scroll = """CustomScrollView(
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
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                              const SizedBox(height: 20),"""

text = text.replace(scroll_pattern.replace('\\s*', ''), new_scroll) # Not regex
text = re.sub(scroll_pattern, new_scroll, text, flags=re.DOTALL)

# 3. Add closing tags for cards and start new ones at boundaries.
# Boundary 1: --- 2. Contact & Location ---
contact_pattern = r'// --- 2\. Contact & Location ---'
contact_repl = """                            ],
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
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                              const SizedBox(height: 20),
"""
text = text.replace(contact_pattern, contact_repl)

# Boundary 2: --- 3. Tags Selection ---
tags_pattern = r'// --- 3\. Tags Selection ---'
tags_repl = """                            ],
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
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                              const SizedBox(height: 20),
"""
text = text.replace(tags_pattern, tags_repl)

# Boundary 4: Remove 'Shop Image' completely from the normal flow because it's now in the header
image_pattern = r'// --- 4\. Shop Image ---.*?const SizedBox\(height: 24\),'
text = re.sub(image_pattern, '', text, flags=re.DOTALL)

# Boundary 5: --- 5. Opening & Closing Time ---
time_pattern = r'// --- 5\. Opening & Closing Time ---'
time_repl = """                            ],
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
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
"""
text = text.replace(time_pattern, time_repl)

# Doctor management needs closing of the card.
# The previous Submit button is what we need to replace with closing the Card and putting the floating bar.
submit_pattern = r'// Submit Button.*?SizedBox\(.*?\),\s*\]\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*,'
submit_repl = """                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),"""
text = re.sub(submit_pattern, submit_repl, text, flags=re.DOTALL)

# Update Scaffold background color
text = text.replace('backgroundColor: Colors.white,', 'backgroundColor: const Color(0xFFF8F9FA),')

# Add the floating button in the Stack
stack_end_pattern = r'if \(_isLoading\)\s*Container\(\s*color: Colors\.black\.withValues\(alpha: 0\.3\),\s*child: const Center\(child: CircularProgressIndicator\(\)\),\s*\),\s*\]\s*,\s*\)'

floating_button = """if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
      )"""
text = re.sub(stack_end_pattern, floating_button, text)

# Add the _buildPremiumHeader method before _buildLabel
header_method = """  Widget _buildPremiumHeader() {
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
            color: Colors.white.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.05),
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
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
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

  Widget _buildLabel(String label) {"""

text = text.replace("  Widget _buildLabel(String label) {", header_method)

# Change Add Business button
text = text.replace("'Add Business'", "'Save Changes'")

with open('lib/screens/business_edit_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)
