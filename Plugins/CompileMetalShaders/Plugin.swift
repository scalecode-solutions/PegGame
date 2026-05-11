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
struct CompileMetalShadersPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        let shadersDir = target.directory.appending("Shaders")
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: shadersDir.string, isDirectory: &isDir),
              isDir.boolValue else {
            return []
        }

        guard let entries = try? fm.contentsOfDirectory(atPath: shadersDir.string) else {
            return []
        }
        let metalFiles = entries
            .filter { $0.hasSuffix(".metal") }
            .sorted()
            .map { shadersDir.appending($0) }
        guard !metalFiles.isEmpty else { return [] }

        let xcrun = Path("/usr/bin/xcrun")
        let workDir = context.pluginWorkDirectory

        var commands: [Command] = []
        var airFiles: [Path] = []

        for metalFile in metalFiles {
            let stem = metalFile.stem
            let airFile = workDir.appending("\(stem).air")
            airFiles.append(airFile)

            commands.append(
                .buildCommand(
                    displayName: "Compile Metal shader \(metalFile.lastComponent)",
                    executable: xcrun,
                    arguments: [
                        "metal",
                        "-c",
                        metalFile.string,
                        "-o",
                        airFile.string,
                    ],
                    inputFiles: [metalFile],
                    outputFiles: [airFile]
                )
            )
        }

        let libFile = workDir.appending("default.metallib")
        commands.append(
            .buildCommand(
                displayName: "Link Metal shaders → default.metallib",
                executable: xcrun,
                arguments: ["metallib", "-o", libFile.string] + airFiles.map(\.string),
                inputFiles: airFiles,
                outputFiles: [libFile]
            )
        )

        return commands
    }
}
