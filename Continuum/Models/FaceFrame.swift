import ARKit
import Foundation

/// One timestamped snapshot of ARKit face blend shapes and head pose.
struct FaceFrame: Codable, Sendable {
    let timestamp: TimeInterval
    let jawOpen: Float
    let mouthClose: Float
    let mouthPucker: Float
    let mouthFunnel: Float
    let mouthSmileLeft: Float
    let mouthSmileRight: Float
    let tongueOut: Float
    let headYaw: Float
    let headPitch: Float
    let headRoll: Float

    /// Builds a frame from an ARKit face anchor at the given media timestamp.
    /// - Parameters:
    ///   - faceAnchor: The tracked face anchor from ARKit.
    ///   - timestamp: Shared media clock time for audio sync.
    /// - Returns: A populated face frame.
    static func from(faceAnchor: ARFaceAnchor, timestamp: TimeInterval) -> FaceFrame {
        let shapes = faceAnchor.blendShapes
        let euler = faceAnchor.transform.eulerAngles

        return FaceFrame(
            timestamp: timestamp,
            jawOpen: floatValue(shapes[.jawOpen]),
            mouthClose: floatValue(shapes[.mouthClose]),
            mouthPucker: floatValue(shapes[.mouthPucker]),
            mouthFunnel: floatValue(shapes[.mouthFunnel]),
            mouthSmileLeft: floatValue(shapes[.mouthSmileLeft]),
            mouthSmileRight: floatValue(shapes[.mouthSmileRight]),
            tongueOut: floatValue(shapes[.tongueOut]),
            headYaw: euler.yaw,
            headPitch: euler.pitch,
            headRoll: euler.roll
        )
    }

    private static func floatValue(_ value: NSNumber?) -> Float {
        value?.floatValue ?? 0
    }
}

private extension simd_float4x4 {
    var eulerAngles: (yaw: Float, pitch: Float, roll: Float) {
        let sy = sqrt(columns.0.x * columns.0.x + columns.1.x * columns.1.x)
        let singular = sy < 1e-6

        let yaw: Float
        let pitch: Float
        let roll: Float

        if !singular {
            yaw = atan2(columns.1.x, columns.0.x)
            pitch = atan2(-columns.2.x, sy)
            roll = atan2(columns.2.y, columns.2.z)
        } else {
            yaw = atan2(-columns.0.y, columns.0.x)
            pitch = atan2(-columns.2.x, sy)
            roll = 0
        }

        return (yaw, pitch, roll)
    }
}
