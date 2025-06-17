// lib/core/services/markdown_parser_service.dart
import 'package:markdown/markdown.dart' as md;
import '../models/content_block_model.dart'; // Adjust path if necessary

List<ContentBlockModel> parseMarkdownToBlocks(String markdownContent) {
  final List<ContentBlockModel> blocks = [];
  int blockCounter = 0;
  String generateBlockId() =>
      "block_${blockCounter++}_${DateTime.now().millisecondsSinceEpoch}";

  // Initialize Document with withSourceSpans as a named parameter
  final doc = md.Document(
    extensionSet: md.ExtensionSet.gitHubWeb,
    encodeHtml: false,
  );

  final List<md.Node> astNodes = doc.parseLines(markdownContent.split('\n'));

  _processAstNodes(
    astNodes,
    0, // initial listLevel
    blocks,
    generateBlockId,
    null, // initial currentListType ('ul' or 'ol')
  );

  // Fallback for content that doesn't result in any blocks
  if (blocks.isEmpty && markdownContent.trim().isNotEmpty) {
    blocks.add(ContentBlockModel(
        id: generateBlockId(),
        type: ContentBlockType.paragraph,
        rawContent: markdownContent.trim()));
  }

  return blocks;
}

// Helper to recursively process AST nodes and convert them to ContentBlockModel
void _processAstNodes(
    List<md.Node> nodes,
    int currentListLevel,
    List<ContentBlockModel> outputBlocks,
    String Function() generateBlockId,
    String? currentListType, // 'ul' or 'ol'
    [int orderedListItemCounter = 1] // For numbering ordered list items
    ) {
  int currentOlCounter = orderedListItemCounter;

  for (final node in nodes) {
    if (node is md.Element) {
      // Use textContent for rawContent, which gives plain text (inline markdown resolved)
      String rawBlockContent = node.textContent.trim();

      switch (node.tag) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          ContentBlockType type;
          if (node.tag == 'h1')
            type = ContentBlockType.h1;
          else if (node.tag == 'h2')
            type = ContentBlockType.h2;
          else if (node.tag == 'h3')
            type = ContentBlockType.h3;
          else if (node.tag == 'h4')
            type = ContentBlockType.h4;
          else if (node.tag == 'h5')
            type = ContentBlockType.h5;
          else
            type = ContentBlockType.h6;
          outputBlocks.add(ContentBlockModel(
              id: generateBlockId(), type: type, rawContent: rawBlockContent));
          break;

        case 'p':
          // Check if this paragraph solely contains an image
          if (node.children != null &&
              node.children!.length == 1 &&
              node.children!.first is md.Element) {
            final childElement = node.children!.first as md.Element;
            if (childElement.tag == 'img') {
              outputBlocks.add(ContentBlockModel(
                id: generateBlockId(),
                type: ContentBlockType.image,
                rawContent: '', // Images don't have text rawContent
                imageUrl: childElement.attributes['src'],
                imageAltText: childElement.attributes['alt'],
              ));
              continue; // Skip creating a paragraph block for this image
            }
          }
          outputBlocks.add(ContentBlockModel(
              id: generateBlockId(),
              type: ContentBlockType.paragraph,
              rawContent: rawBlockContent));
          break;

        case 'pre': // Fenced code block or indented code block
          String code = '';
          String? lang;
          // Fenced code blocks usually have a <code> child.
          if (node.children != null &&
              node.children!.isNotEmpty &&
              node.children!.first is md.Element) {
            final codeElement = node.children!.first as md.Element;
            if (codeElement.tag == 'code') {
              code =
                  codeElement.textContent; // textContent is correct for <code>
              final classAttr = codeElement.attributes['class'];
              if (classAttr != null && classAttr.startsWith('language-')) {
                lang = classAttr.substring('language-'.length).trim();
                if (lang.isEmpty) lang = null;
              }
            } else {
              // Indented code block might not have a <code> child directly under <pre> in some ASTs
              code = node.textContent;
            }
          } else {
            // Fallback for indented code if no children or not an Element
            code = node.textContent;
          }
          outputBlocks.add(ContentBlockModel(
              id: generateBlockId(),
              type: ContentBlockType.codeBlock,
              rawContent: code, // The code itself is the raw content
              codeLanguage: lang));
          break;

        case 'blockquote':
          outputBlocks.add(ContentBlockModel(
              id: generateBlockId(),
              type: ContentBlockType.blockquote,
              rawContent:
                  rawBlockContent)); // Plain text content of the blockquote
          break;

        case 'ul':
        case 'ol':
          int startNumberForThisList = 1;
          if (node.tag == 'ol') {
            final startAttr = node.attributes['start'];
            if (startAttr != null) {
              startNumberForThisList = int.tryParse(startAttr) ?? 1;
            }
          }
          // Recursively process children (which should be <li> items)
          _processAstNodes(
              node.children ?? [], // Ensure children is not null
              currentListLevel + 1,
              outputBlocks,
              generateBlockId,
              node.tag, // Pass 'ul' or 'ol' as the currentListType
              startNumberForThisList);
          break;

        case 'li':
          if (currentListType != null) {
            // Ensure we are processing an item of a known list
            // For <li>, rawContent will be its plain text content, excluding nested lists.
            String liTextContent = _getLiDirectTextContent(node.children ?? []);

            outputBlocks.add(ContentBlockModel(
              id: generateBlockId(),
              type: currentListType == 'ul'
                  ? ContentBlockType.unorderedListItem
                  : ContentBlockType.orderedListItem,
              rawContent: liTextContent,
              listLevel: currentListLevel,
              listMarker: currentListType == 'ol' ? "$currentOlCounter." : null,
            ));
            if (currentListType == 'ol') currentOlCounter++;

            // After adding the <li> block, process any nested lists *within* this <li>
            if (node.children != null) {
              for (final childNode in node.children!) {
                if (childNode is md.Element &&
                    (childNode.tag == 'ul' || childNode.tag == 'ol')) {
                  int nestedStartNumber = 1;
                  if (childNode.tag == 'ol') {
                    final startAttr = childNode.attributes['start'];
                    if (startAttr != null)
                      nestedStartNumber = int.tryParse(startAttr) ?? 1;
                  }
                  // The list itself ('ul' or 'ol') is processed. Its children (<li>)
                  // will inherit the incremented listLevel from this call.
                  _processAstNodes(
                      [childNode], // Process the list element itself
                      currentListLevel, // The list items of this nested list will be at currentListLevel + 1
                      outputBlocks,
                      generateBlockId,
                      null, // Let the recursive call for 'ul'/'ol' set its type
                      nestedStartNumber);
                }
              }
            }
          }
          break;

        case 'hr':
          outputBlocks.add(ContentBlockModel(
              id: generateBlockId(),
              type: ContentBlockType.horizontalRule,
              rawContent: ''));
          break;

        case 'img': // Direct image tag (less common as top-level block)
          outputBlocks.add(ContentBlockModel(
            id: generateBlockId(),
            type: ContentBlockType.image,
            rawContent: '',
            imageUrl: node.attributes['src'],
            imageAltText: node.attributes['alt'],
          ));
          break;

        default:
          // For unhandled block elements, if they have children, try to process them.
          if (node.children != null && node.children!.isNotEmpty) {
            _processAstNodes(
                node.children!,
                currentListLevel,
                outputBlocks,
                generateBlockId,
                currentListType, // Propagate currentListType if within a list context
                currentOlCounter);
          }
          break;
      }
    }
    // Top-level md.Text nodes are generally not expected from doc.parseLines()
    // as text is usually wrapped in <p> or part of other elements.
    // If they do occur and need handling, add logic here.
  }
}

// Helper to get the direct plain text content of an <li> element,
// excluding the text content of any nested <ul> or <ol> lists.
String _getLiDirectTextContent(List<md.Node> liChildren) {
  StringBuffer buffer = StringBuffer();
  for (final child in liChildren) {
    // Skip processing of nested list elements for the parent li's direct content
    if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
      continue;
    }
    // Append textContent of all other direct children (text nodes, inline elements)
    buffer.write(child.textContent);
    // Add a space if it's an element and not the last child, to prevent words mashing.
    // This is a heuristic; precise spacing from original Markdown is lost with textContent.
    if (child is md.Element && child != liChildren.last) {
      // Check if the buffer doesn't already end with a space
      if (buffer.isNotEmpty && buffer.toString()[buffer.length - 1] != ' ') {
        buffer.write(' ');
      }
    }
  }
  // Replace multiple spaces with a single space and trim.
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
