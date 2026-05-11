import Foundation
import PackagePlugin

/// SPM build-tool plugin that compiles the `.metal` files in
/// `Sources/PegGameUI/Shaders/` into a single `default.metallib` resource.
///
/// The Metal toolchain lives at a cryptex-mounted path that changes between
/// OS updates, so we invoke it via `/usr/bin/xcrun metal` and `/usr/bin/xcrun
/// metallib` instead of resolving the tools through `context.tool(named:)`
/// (which can't find them).
///
/// The resulting library lands in PegGameUI's resource bundle, where
/// `ShaderLibrary.bundle(.module)` can resolve it at runtime.
@main
struct PGShadersPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        let shadersDir = target.directoryURL.appending(path: "Shaders")
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: shadersDir.path(percentEncoded: false), isDirectory: &isDir),
              isDir.boolValue else {
            return []
        }

        guard let entries = try? fm.contentsOfDirectory(atPath: shadersDir.path(percentEncoded: false)) else {
            return []
        }
        let metalFiles = entries
            .filter { $0.hasSuffix(".metal") }
            .sorted()
            .map { shadersDir.appending(path: $0) }
        guard !metalFiles.isEmpty else { return [] }

        let xcrun = URL(fileURLWithPath: "/usr/bin/xcrun")
        let workDir = context.pluginWorkDirectoryURL

        var commands: [Command] = []
        var airFiles: [URL] = []

        for metalFile in metalFiles {
            let stem = metalFile.deletingPathExtension().lastPathComponent
            let airFile = workDir.appending(path: "\(stem).air")
            airFiles.append(airFile)

            commands.append(
                .buildCommand(
                    displayName: "Compile Metal shader \(metalFile.lastPathComponent)",
                    executable: xcrun,
                    arguments: [
                        "metal",
                        "-c",
                        metalFile.path(percentEncoded: false),
                        "-o",
                        airFile.path(percentEncoded: false),
                    ],
                    inputFiles: [metalFile],
                    outputFiles: [airFile]
                )
            )
        }

        let libFile = workDir.appending(path: "default.metallib")
        commands.append(
            .buildCommand(
                displayName: "Link Metal shaders → default.metallib",
                executable: xcrun,
                arguments: ["metallib", "-o", libFile.path(percentEncoded: false)]
                    + airFiles.map { $0.path(percentEncoded: false) },
                inputFiles: airFiles,
                outputFiles: [libFile]
            )
        )

        return commands
    }
}
