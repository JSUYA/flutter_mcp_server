import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:mcp_server/mcp_server.dart';
import 'package:logger/logger.dart' as ext_logger;

final Logger _logger = Logger('mcp_server_example');

void main(List<String> args) async {
  // _logger.level = Level.debug; // LogLevel not available in current Logger

  // MCP STDIO Mode
  if (args.contains('--mcp-stdio-mode')) {
    await startMcpServer(mode: 'stdio');
  } else {
    // SSE Mode
    int port = 8080;
    await startMcpServer(mode: 'sse', port: port);
  }
}

Future<void> startMcpServer({required String mode, int port = 8080}) async {
  try {
    final serverResult = await McpServer.createAndStart(
      config: McpServer.simpleConfig(
        name: 'Flutter MCP Server',
        version: '1.0.0',
        enableDebugLogging: true,
      ),
      transportConfig:
          mode == 'stdio'
              ? TransportConfig.stdio()
              : TransportConfig.sse(
                endpoint: '/sse',
                messagesEndpoint: '/message',
                host: 'localhost',
                port: port,
              ),
    );

    await serverResult.fold(
      (server) async {
        // Register tools, resources, and prompts
        _registerTools(server);
        _registerResources(server);
        // _registerPrompts(server);

        // Set up transport closure handling
        server.onDisconnect.listen((_) {
          _logger.debug('Client disconnected, shutting down.');
          exit(0);
        });

        // Send initial log message
        server.sendLog(
          McpLogLevel.info,
          'Flutter MCP Server started successfully',
        );

        if (mode == 'sse') {
          _logger.debug('SSE Server is running on:');
          _logger.debug('- SSE endpoint:     http://localhost:$port/sse');
          _logger.debug('- Message endpoint: http://localhost:$port/message');
          _logger.debug('Press Ctrl+C to stop the server');
        } else {
          _logger.debug('STDIO Server initialized and connected to transport');
        }

        // Keep server running
        await Future.delayed(const Duration(hours: 24)); // Run for 24 hours
      },
      (error) {
        _logger.debug('Error initializing MCP server: $error');
        exit(1);
      },
    );
  } catch (e, stackTrace) {
    _logger.debug('Error initializing MCP server: $e');
    _logger.debug(stackTrace.toString());
    exit(1);
  }
}

void _registerTools(Server server) {
  // Analyze
  server.addTool(
    name: 'analyze',
    description: 'Analyze Dart code using dart analyze',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {
          'type': 'string',
          'description': 'File or directory to format',
        },
        'workingDirectory': {
          'type': 'string',
          'description': 'Current working directory absolute path.',
        },
      },
    },
    handler: (input) async {
      _logger.debug('Running analyze tool');
      final workingDir =
          input['workingDirectory']?.toString() ?? Directory.current.path;

      // await Process.run('cd', [workingDir]);

      final result = await Process.run('dart', [
        'analyze',
      ], workingDirectory: workingDir);

      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );
  /*
  // Format
  server.addTool(
    name: 'format',
    description: 'Format Dart code using dart format',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {
          'type': 'string',
          'description': 'File or directory to format',
        },
      },
      'required': [],
    },
    handler: (input) async {
      _logger.debug('Running format tool');
      final path = input['path']?.toString() ?? '.';
      final result = await Process.run('dart', ['format', path]);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );

  // Fix
  server.addTool(
    name: 'fix',
    description: 'Apply Dart fixes using dart fix --apply',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running fix tool');
      final result = await Process.run('dart', ['fix', '--apply']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );

  // Create
  server.addTool(
    name: 'create',
    description: 'Create a new Dart or Flutter project',
    inputSchema: {
      'type': 'object',
      'properties': {
        'template': {
          'type': 'string',
          'description': 'Project template (console, package, flutter, etc.)',
        },
        'path': {
          'type': 'string',
          'description': 'Directory to create project in',
        },
      },
      'required': ['path'],
    },
    handler: (input) async {
      _logger.debug('Running create tool');
      final template = input['template']?.toString();
      final path = input['path']?.toString() ?? 'new_project';
      final args = <String>['create'];
      if (template != null) args.addAll(['-t', template]);
      args.add(path);
      final result = await Process.run('dart', args);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );
*/
  // Run
  server.addTool(
    name: 'run',
    description: 'Run flutter-tizne app',
    inputSchema: {
      'type': 'object',
      'properties': {
        'entrypoint': {
          'type': 'string',
          'description': 'Entrypoint file (main.dart) or directory',
        },
        'workingDirectory': {
          'type': 'string',
          'description': 'Current working directory absolute path.',
        },
      },
      'required': [],
    },
    handler: (input) async {
      _logger.debug('Running run tool');
      final entrypoint = input['entrypoint']?.toString();
      final workingDir =
          input['workingDirectory']?.toString() ?? Directory.current.path;
      final args = <String>['run'];
      if (entrypoint != null) args.add(entrypoint);
      final result = await Process.run(
        'flutter-tizen',
        args,
        workingDirectory: workingDir,
      );
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );
  /*
  // Test
  server.addTool(
    name: 'test',
    description: 'Run Dart tests',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': 'Test file or directory'},
      },
      'required': [],
    },
    handler: (input) async {
      _logger.debug('Running test tool');
      final path = input['path']?.toString();
      final args = <String>['test'];
      if (path != null) args.add(path);
      final result = await Process.run('dart', args);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );

  // get_diagnostics (alias for analyze)
  server.addTool(
    name: 'get_diagnostics',
    description: 'Get diagnostics for Dart/Flutter code (alias for analyze)',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running get_diagnostics tool');
      final result = await Process.run('dart', ['analyze']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );

  // apply_fixes (alias for fix)
  server.addTool(
    name: 'apply_fixes',
    description: 'Apply fixes to Dart code (alias for fix)',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running apply_fixes tool');
      final result = await Process.run('dart', ['fix', '--apply']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content: [TextContent(text: output)]);
    },
  );

  // flutter_inspector (stub, as it requires DevTools integration)
  server.addTool(
    name: 'flutter_inspector',
    description: 'Flutter Inspector integration (requires DevTools, stub)',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running flutter_inspector tool');
      return CallToolResult(
        content: [
          TextContent(
            text:
                'Flutter Inspector is not implemented in this server. Use DevTools for widget inspection.',
          ),
        ],
      );
    },
  );*/
}

// --- Resource caching example ---
final Map<String, String> _resourceCache = {};

void _registerResources(Server server) {
  server.addResource(
    name: 'example_resource',
    uri: '/example_resource',
    description: 'Returns a static value, cached for repeated queries.',
    mimeType: 'text/plain',
    handler: (String resourceName, Map<String, dynamic> input) async {
      final query = '${input['query']}';
      if (_resourceCache.containsKey(query)) {
        return CallToolResult(
          content: [TextContent(text: '[CACHED] ' + _resourceCache[query]!)],
        );
      }
      // Simulate a slow resource fetch
      await Future.delayed(Duration(milliseconds: 500));
      final value = 'Resource value for query: $query';
      _resourceCache[query] = value;
      return CallToolResult(content: [TextContent(text: value)]);
    },
  );

  // --- Phase 5: Real resource endpoints for LLMs ---
  final Map<String, String> _newsCache = {};
  final Map<String, String> _docCache = {};
  final Map<String, String> _exampleCache = {};

  server.addResource(
    name: 'flutter_news_resource',
    uri: '/flutter_news_resource',
    description:
        'Fetches the latest Flutter/Dart news headlines and changelogs.',
    mimeType: 'text/plain',
    handler: (String resourceName, Map<String, dynamic> input) async {
      final topic = '${input['topic']}';
      if (_newsCache.containsKey(topic)) {
        return CallToolResult(
          content: [TextContent(text: '[CACHED] ' + _newsCache[topic]!)],
        );
      }
      // For demo: fetch from public URLs (could use http package for real fetch)
      String news = '';
      if (topic.toLowerCase().contains('flutter')) {
        news =
            'See https://docs.flutter.dev/release/whats-new for Flutter news.';
      } else if (topic.toLowerCase().contains('dart')) {
        news = 'See https://dart.dev/guides/whats-new for Dart news.';
      } else if (topic.toLowerCase().contains('changelog')) {
        news =
            'See https://github.com/flutter/flutter/releases for changelogs.';
      } else {
        news = 'No news found for topic: $topic.';
      }
      _newsCache[topic] = news;
      return CallToolResult(content: [TextContent(text: news)]);
    },
  );

  server.addResource(
    name: 'dart_doc_resource',
    uri: '/dart_doc_resource',
    description:
        'Returns official documentation links and summaries for Dart/Flutter topics.',
    mimeType: 'text/plain',
    handler: (String resourceName, Map<String, dynamic> input) async {
      final query = '${input['query']}';
      if (_docCache.containsKey(query)) {
        return CallToolResult(
          content: [TextContent(text: '[CACHED] ' + _docCache[query]!)],
        );
      }
      // For demo: simple keyword matching
      String doc = '';
      if (query.toLowerCase().contains('http')) {
        doc = 'Dart http docs: https://pub.dev/packages/http';
      } else if (query.toLowerCase().contains('state')) {
        doc =
            'Flutter state management: https://docs.flutter.dev/data-and-backend/state-mgmt/options';
      } else {
        doc =
            'Try searching https://dart.dev or https://docs.flutter.dev for "$query".';
      }
      _docCache[query] = doc;
      return CallToolResult(content: [TextContent(text: doc)]);
    },
  );

  server.addResource(
    name: 'community_examples_resource',
    uri: '/community_examples_resource',
    description:
        'Returns links to community-curated code examples and patterns.',
    mimeType: 'text/plain',
    handler: (String resourceName, Map<String, dynamic> input) async {
      final topic = '${input['topic']}';
      if (_exampleCache.containsKey(topic)) {
        return CallToolResult(
          content: [TextContent(text: '[CACHED] ' + _exampleCache[topic]!)],
        );
      }
      // For demo: simple topic matching
      String example = '';
      if (topic.toLowerCase().contains('bloc')) {
        example = 'See https://bloclibrary.dev/#/ for Bloc pattern examples.';
      } else if (topic.toLowerCase().contains('provider')) {
        example =
            'See https://pub.dev/packages/provider for Provider examples.';
      } else if (topic.toLowerCase().contains('navigation')) {
        example = 'Flutter navigation: https://docs.flutter.dev/ui/navigation';
      } else {
        example =
            'Try https://flutterawesome.com or https://pub.dev for "$topic".';
      }
      _exampleCache[topic] = example;
      return CallToolResult(content: [TextContent(text: example)]);
    },
  );

  // --- Phase 5: Natural language search tool for docs/resources ---
  server.addTool(
    name: 'search_docs',
    description:
        'Searches official and community docs/resources for a natural language query.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Natural language query'},
      },
      'required': ['query'],
    },
    handler: (input) async {
      final query = input['query'] as String;
      // For demo: simple keyword-based aggregation
      final List<String> results = [];
      // News
      if (_newsCache.containsKey(query)) results.add(_newsCache[query]!);
      // Docs
      if (_docCache.containsKey(query)) results.add(_docCache[query]!);
      // Examples
      if (_exampleCache.containsKey(query)) results.add(_exampleCache[query]!);
      // Fallback
      if (results.isEmpty) {
        results.add(
          'No cached result. Try https://dart.dev/search?q=${Uri.encodeComponent(query)} or https://docs.flutter.dev/search?q=${Uri.encodeComponent(query)}',
        );
      }
      return CallToolResult(
        content: [TextContent(text: results.join('\n---\n'))],
      );
    },
  );
}
/*
void _registerPrompts(Server server) {
  // Simple greeting prompt
  server.addPrompt(
    name: 'greeting',
    description: 'Generate a greeting for a user',
    arguments: [
      PromptArgument(
        name: 'name',
        description: 'Name of the person to greet',
        required: true,
      ),
      PromptArgument(
        name: 'formal',
        description: 'Whether to use formal greeting style',
        required: false,
      ),
    ],
    handler: (args) async {
      final name = args['name'] as String;
      final formal = args['formal'] as bool? ?? false;

      final String systemPrompt = formal
          ? 'You are a formal assistant. Address the user with respect and formality.'
          : 'You are a friendly assistant. Be warm and casual in your tone.';

      final messages = [
        Message(
          role: MessageRole.system.toString().split('.').last,
          content: TextContent(text: systemPrompt),
        ),
        Message(
          role: MessageRole.user.toString().split('.').last,
          content: TextContent(text: 'Please greet $name'),
        ),
      ];

      return GetPromptResult(
        description: 'A ${formal ? 'formal' : 'casual'} greeting for $name',
        messages: messages,
      );
    },
  );

  // Code review prompt
  server.addPrompt(
    name: 'codeReview',
    description: 'Generate a code review for a code snippet',
    arguments: [
      PromptArgument(
        name: 'code',
        description: 'Code to review',
        required: true,
      ),
      PromptArgument(
        name: 'language',
        description: 'Programming language of the code',
        required: true,
      ),
    ],
    handler: (args) async {
      final code = args['code'] as String;
      final language = args['language'] as String;

      final systemPrompt = '''
You are an expert code reviewer. Review the provided code with these guidelines:
1. Identify potential bugs or issues
2. Suggest optimizations for performance or readability
3. Highlight good practices used in the code
4. Provide constructive feedback for improvements
Be specific in your feedback and provide code examples when suggesting changes.
''';

      final messages = [
        Message(
          role: MessageRole.system.toString().split('.').last,
          content: TextContent(text: systemPrompt),
        ),
        Message(
          role: MessageRole.user.toString().split('.').last,
          content: TextContent(text: 'Please review this $language code:\n\n```$language\n$code\n```')
          ,
        ),
      ];

      return GetPromptResult(
        description: 'Code review for $language code',
        messages: messages,
      );
    },
  );
}*/

/*import 'package:mcp_server/mcp_server.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logger/logger.dart' as ext_logger;
import 'dart:io';


void main(List<String> args) async {
  // _logger.setLevel(LogLevel.debug); // LogLevel not available in current Logger
  
  // MCP STDIO Mode
  if (args.contains('--mcp-stdio-mode')) {
    await startMcpServer(mode: 'stdio');
  } else {
    // SSE Mode
    int port = 8999;
    await startMcpServer(mode: 'sse', port: port);
  }
}


Future<void> startMcpServer({required String mode, int port = 8080}) async {
  // Load environment variables (optional, for local dev)
  print('ddd');
  // final dotEnv = DotEnv()..load();

  final logger = ext_logger.Logger();
  McpServerConfig config = McpServerConfig(name: 'Flutter MCP Server',
    version: '1.0.0',
    capabilities: ServerCapabilities(
      tools: ToolsCapability(listChanged: true, supportsProgress: true, supportsCancellation: true,),
      resources: ResourcesCapability(listChanged: true, subscribe: true,), // Enable resources capability
      prompts: PromptsCapability(listChanged: true),
    ),);
  final server = McpServer.createServer(
    config,
  );
  
// Register real MCP tools
void registerMcpTools() {
  // Analyze
  server.addTool(
    name: 'analyze',
    description: 'Analyze Dart code using dart analyze',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running analyze tool');
      final result = await Process.run('dart', ['analyze']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(
        content: [
        TextContent(text: output)
      ]);
    },
  );

  // Format
  server.addTool(
    name: 'format',
    description: 'Format Dart code using dart format',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': 'File or directory to format'}
      },
      'required': []
    },
    handler: (input) async {
      _logger.debug('Running format tool');
      final path = input['path']?.toString() ?? '.';
      final result = await Process.run('dart', ['format', path]);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // Fix
  server.addTool(
    name: 'fix',
    description: 'Apply Dart fixes using dart fix --apply',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running fix tool');
      final result = await Process.run('dart', ['fix', '--apply']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // Create
  server.addTool(
    name: 'create',
    description: 'Create a new Dart or Flutter project',
    inputSchema: {
      'type': 'object',
      'properties': {
        'template': {'type': 'string', 'description': 'Project template (console, package, flutter, etc.)'},
        'path': {'type': 'string', 'description': 'Directory to create project in'}
      },
      'required': ['path']
    },
    handler: (input) async {
      _logger.debug('Running create tool');
      final template = input['template']?.toString();
      final path = input['path']?.toString() ?? 'new_project';
      final args = <String>['create'];
      if (template != null) args.addAll(['-t', template]);
      args.add(path);
      final result = await Process.run('dart', args);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // Run
  server.addTool(
    name: 'run',
    description: 'Run a Dart or Flutter app',
    inputSchema: {
      'type': 'object',
      'properties': {
        'entrypoint': {'type': 'string', 'description': 'Entrypoint file (main.dart) or directory'}
      },
      'required': []
    },
    handler: (input) async {
      _logger.debug('Running run tool');
      final entrypoint = input['entrypoint']?.toString();
      final args = <String>['run'];
      if (entrypoint != null) args.add(entrypoint);
      final result = await Process.run('dart', args);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // Test
  server.addTool(
    name: 'test',
    description: 'Run Dart tests',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': 'Test file or directory'}
      },
      'required': []
    },
    handler: (input) async {
      _logger.debug('Running test tool');
      final path = input['path']?.toString();
      final args = <String>['test'];
      if (path != null) args.add(path);
      final result = await Process.run('dart', args);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // get_diagnostics (alias for analyze)
  server.addTool(
    name: 'get_diagnostics',
    description: 'Get diagnostics for Dart/Flutter code (alias for analyze)',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running get_diagnostics tool');
      final result = await Process.run('dart', ['analyze']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // apply_fixes (alias for fix)
  server.addTool(
    name: 'apply_fixes',
    description: 'Apply fixes to Dart code (alias for fix)',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running apply_fixes tool');
      final result = await Process.run('dart', ['fix', '--apply']);
      final output = result.stdout.toString() + result.stderr.toString();
      return CallToolResult(content:[
        TextContent(text: output)
      ]);
    },
  );

  // flutter_inspector (stub, as it requires DevTools integration)
  server.addTool(
    name: 'flutter_inspector',
    description: 'Flutter Inspector integration (requires DevTools, stub)',
    inputSchema: {'type': 'object'},
    handler: (input) async {
      _logger.debug('Running flutter_inspector tool');
      return CallToolResult(content:[
        TextContent(text: 'Flutter Inspector is not implemented in this server. Use DevTools for widget inspection.')
      ]);
    },
  );
}

registerMcpTools();

// --- Resource caching example ---
final Map<String, String> _resourceCache = {};

server.addResource(
  name: 'example_resource',
  uri: '/example_resource',
  description: 'Returns a static value, cached for repeated queries.',
  mimeType: 'text/plain',
  handler: (String resourceName, Map<String, dynamic> input) async {
    final query = '${input['query']}';
    if (_resourceCache.containsKey(query)) {
      return CallToolResult(content:[
        TextContent(text: '[CACHED] ' + _resourceCache[query]!)
      ]);
    }
    // Simulate a slow resource fetch
    await Future.delayed(Duration(milliseconds: 500));
    final value = 'Resource value for query: $query';
    _resourceCache[query] = value;
    return CallToolResult(content:[
      TextContent(text: value)
    ]);
  },
);

// --- Phase 5: Real resource endpoints for LLMs ---
final Map<String, String> _newsCache = {};
final Map<String, String> _docCache = {};
final Map<String, String> _exampleCache = {};

server.addResource(
  name: 'flutter_news_resource',
  uri: '/flutter_news_resource',
  description: 'Fetches the latest Flutter/Dart news headlines and changelogs.',
  mimeType: 'text/plain',
  handler: (String resourceName, Map<String, dynamic> input) async {
    final topic = '${input['topic']}';
    if (_newsCache.containsKey(topic)) {
      return CallToolResult(content:[
        TextContent(text: '[CACHED] ' + _newsCache[topic]!)
      ]);
    }
    // For demo: fetch from public URLs (could use http package for real fetch)
    String news = '';
    if (topic.toLowerCase().contains('flutter')) {
      news = 'See https://docs.flutter.dev/release/whats-new for Flutter news.';
    } else if (topic.toLowerCase().contains('dart')) {
      news = 'See https://dart.dev/guides/whats-new for Dart news.';
    } else if (topic.toLowerCase().contains('changelog')) {
      news = 'See https://github.com/flutter/flutter/releases for changelogs.';
    } else {
      news = 'No news found for topic: $topic.';
    }
    _newsCache[topic] = news;
    return CallToolResult(content:[
      TextContent(text: news)
    ]);
  },
);

server.addResource(
  name: 'dart_doc_resource',
  uri: '/dart_doc_resource',
  description: 'Returns official documentation links and summaries for Dart/Flutter topics.',
  mimeType: 'text/plain',
  handler: (String resourceName, Map<String, dynamic> input) async {
    final query = '${input['query']}';
    if (_docCache.containsKey(query)) {
      return CallToolResult(content:[
        TextContent(text: '[CACHED] ' + _docCache[query]!)
      ]);
    }
    // For demo: simple keyword matching
    String doc = '';
    if (query.toLowerCase().contains('http')) {
      doc = 'Dart http docs: https://pub.dev/packages/http';
    } else if (query.toLowerCase().contains('state')) {
      doc = 'Flutter state management: https://docs.flutter.dev/data-and-backend/state-mgmt/options';
    } else {
      doc = 'Try searching https://dart.dev or https://docs.flutter.dev for "$query".';
    }
    _docCache[query] = doc;
    return CallToolResult(content:[
      TextContent(text: doc)
    ]);
  },
);

server.addResource(
  name: 'community_examples_resource',
  uri: '/community_examples_resource',
  description: 'Returns links to community-curated code examples and patterns.',
  mimeType: 'text/plain',
  handler: (String resourceName, Map<String, dynamic> input) async {
    final topic = '${input['topic']}';
    if (_exampleCache.containsKey(topic)) {
      return CallToolResult(content:[
        TextContent(text: '[CACHED] ' + _exampleCache[topic]!)
      ]);
    }
    // For demo: simple topic matching
    String example = '';
    if (topic.toLowerCase().contains('bloc')) {
      example = 'See https://bloclibrary.dev/#/ for Bloc pattern examples.';
    } else if (topic.toLowerCase().contains('provider')) {
      example = 'See https://pub.dev/packages/provider for Provider examples.';
    } else if (topic.toLowerCase().contains('navigation')) {
      example = 'Flutter navigation: https://docs.flutter.dev/ui/navigation';
    } else {
      example = 'Try https://flutterawesome.com or https://pub.dev for "$topic".';
    }
    _exampleCache[topic] = example;
    return CallToolResult(content:[
      TextContent(text: example)
    ]);
  },
);

// --- Phase 5: Natural language search tool for docs/resources ---
server.addTool(
  name: 'search_docs',
  description: 'Searches official and community docs/resources for a natural language query.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'description': 'Natural language query'}
    },
    'required': ['query']
  },
  handler: (input) async {
    final query = input['query'] as String;
    // For demo: simple keyword-based aggregation
    final List<String> results = [];
    // News
    if (_newsCache.containsKey(query)) results.add(_newsCache[query]!);
    // Docs
    if (_docCache.containsKey(query)) results.add(_docCache[query]!);
    // Examples
    if (_exampleCache.containsKey(query)) results.add(_exampleCache[query]!);
    // Fallback
    if (results.isEmpty) {
      results.add('No cached result. Try https://dart.dev/search?q=${Uri.encodeComponent(query)} or https://docs.flutter.dev/search?q=${Uri.encodeComponent(query)}');
    }
    return CallToolResult(content:[
      TextContent(text: results.join('\n---\n'))
    ]);
  },
);

// Start the server (stdio)
print('aa000');
final transport = McpServer.createStdioTransport();

print('aa111');
server.connect(transport.get());

}
*/
