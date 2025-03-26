const std = @import("std");
const fs = std.fs;
const process = std.process;
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    
    if (args.len < 3) {
        std.debug.print("Usage: {s} <src-dir> <output-dir>\n", .{args[0]});
        return error.InvalidArguments;
    }
    
    const src_dir = args[1];
    const output_dir = args[2];
    
    try fs.cwd().makePath(output_dir);
    try processDirectory(allocator, src_dir, output_dir);
    
    // Generate index file
    try generateIndex(allocator, src_dir, output_dir);
    
    std.debug.print("Documentation generated in {s}\n", .{output_dir});
}

fn processDirectory(allocator: mem.Allocator, src_path: []const u8, output_path: []const u8) !void {
    var src_dir = try fs.cwd().openDir(src_path, .{ .iterate = true });
    defer src_dir.close();
    
    var iter = src_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .Directory) {
            // Process subdirectory
            const new_src_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ src_path, entry.name });
            defer allocator.free(new_src_path);
            
            const new_output_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ output_path, entry.name });
            defer allocator.free(new_output_path);
            
            try fs.cwd().makePath(new_output_path);
            try processDirectory(allocator, new_src_path, new_output_path);
        } else if (entry.kind == .File) {
            // Process file
            if (std.mem.endsWith(u8, entry.name, ".zig")) {
                try processZigFile(allocator, src_path, entry.name, output_path);
            }
        }
    }
}

fn processZigFile(allocator: mem.Allocator, src_path: []const u8, file_name: []const u8, output_path: []const u8) !void {
    const file_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ src_path, file_name });
    defer allocator.free(file_path);
    
    const file = try fs.cwd().openFile(file_path, .{});
    defer file.close();
    
    const file_content = try file.readToEndAlloc(allocator, 1024 * 1024 * 10); // 10MB max
    defer allocator.free(file_content);
    
    // Create output markdown file
    const md_file_name = try std.fmt.allocPrint(allocator, "{s}/{s}.md", .{ output_path, mem.sliceTo(file_name, '.') });
    defer allocator.free(md_file_name);
    
    var md_file = try fs.cwd().createFile(md_file_name, .{});
    defer md_file.close();
    
    // Write header
    const header = try std.fmt.allocPrint(allocator, "# {s}\n\n", .{file_name});
    defer allocator.free(header);
    try md_file.writeAll(header);
    
    // Extract documentation comments
    var doc_sections = std.ArrayList([]const u8).init(allocator);
    defer doc_sections.deinit();
    
    var lines = std.mem.split(u8, file_content, "\n");
    var in_doc_comment = false;
    var current_section = std.ArrayList(u8).init(allocator);
    defer current_section.deinit();
    
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        
        if (std.mem.startsWith(u8, trimmed, "/// ")) {
            // Documentation comment
            if (!in_doc_comment) {
                in_doc_comment = true;
                current_section = std.ArrayList(u8).init(allocator);
            }
            
            const comment_text = trimmed[4..]; // Skip "/// "
            try current_section.appendSlice(comment_text);
            try current_section.append('\n');
        } else if (std.mem.startsWith(u8, trimmed, "pub ")) {
            // Public declaration
            if (in_doc_comment) {
                // End of doc comment section, store it with the declaration
                try current_section.appendSlice("\n```zig\n");
                try current_section.appendSlice(trimmed);
                try current_section.appendSlice("\n```\n\n");
                
                const section_str = try current_section.toOwnedSlice();
                try doc_sections.append(section_str);
                
                in_doc_comment = false;
            }
        } else if (in_doc_comment) {
            // End of doc comment without a public declaration
            const section_str = try current_section.toOwnedSlice();
            try doc_sections.append(section_str);
            in_doc_comment = false;
        }
    }
    
    // Write all doc sections to the markdown file
    for (doc_sections.items) |section| {
        try md_file.writeAll(section);
        try md_file.writeAll("\n");
    }
}

fn generateIndex(allocator: mem.Allocator, src_path: []const u8, output_path: []const u8) !void {
    const index_path = try std.fmt.allocPrint(allocator, "{s}/index.md", .{output_path});
    defer allocator.free(index_path);
    
    var index_file = try fs.cwd().createFile(index_path, .{});
    defer index_file.close();
    
    try index_file.writeAll("# TURMOIL API Documentation\n\n");
    try index_file.writeAll("## Modules\n\n");
    
    try writeIndexForDirectory(allocator, index_file, src_path, output_path, "");
}

fn writeIndexForDirectory(
    allocator: mem.Allocator, 
    index_file: fs.File, 
    src_path: []const u8, 
    output_path: []const u8, 
    prefix: []const u8
) !void {
    var src_dir = try fs.cwd().openDir(src_path, .{ .iterate = true });
    defer src_dir.close();
    
    var iter = src_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .Directory) {
            const dir_header = try std.fmt.allocPrint(allocator, "### {s}{s}\n\n", .{ prefix, entry.name });
            defer allocator.free(dir_header);
            try index_file.writeAll(dir_header);
            
            const new_src_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ src_path, entry.name });
            defer allocator.free(new_src_path);
            
            const new_output_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ output_path, entry.name });
            defer allocator.free(new_output_path);
            
            const new_prefix = try std.fmt.allocPrint(allocator, "{s}{s}/", .{ prefix, entry.name });
            defer allocator.free(new_prefix);
            
            try writeIndexForDirectory(allocator, index_file, new_src_path, new_output_path, new_prefix);
        } else if (entry.kind == .File and std.mem.endsWith(u8, entry.name, ".zig")) {
            const file_link = try std.fmt.allocPrint(allocator, "- [{s}]({s}{s}.md)\n", 
                .{ entry.name, prefix, mem.sliceTo(entry.name, '.') });
            defer allocator.free(file_link);
            try index_file.writeAll(file_link);
        }
    }
} 