import Foundation
import Vision
import AppKit

func recognizeText(in imageURL: URL) -> String {
    guard let image = NSImage(contentsOf: imageURL) else { return "" }
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let cgImage = bitmap.cgImage else { return "" }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do { try handler.perform([request]) } catch { return "" }

    let observations = request.results ?? []
    return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

let dir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fm = FileManager.default
let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?.filter { $0.pathExtension.lowercased() == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
for file in files {
    let text = recognizeText(in: file)
    print("FILE:\(file.lastPathComponent)")
    print(text)
    print("<<<END>>>")
}
