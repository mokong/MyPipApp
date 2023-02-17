//
//  UIPiPView.swift
//  UIPiPView
//
//  Created by Akihiro Urushihara on 2021/12/12.
//

import UIKit
import AVKit
import AVFoundation

open class UIPiPView: UIView,
    AVPictureInPictureControllerDelegate,
    AVPictureInPictureSampleBufferPlaybackDelegate {

    /// Returns whether or not UIPiPView is supported.
    /// It depends on the iOS version, also note that it cannot be used with the iOS simulator.
    static public func isUIPiPViewSupported() -> Bool {
        if AVPictureInPictureController.isPictureInPictureSupported(), #available(iOS 15.0, *) {
            return true }
        return false
    }

    public let pipBufferDisplayLayer = AVSampleBufferDisplayLayer()

    private var pipController: AVPictureInPictureController?
    private var pipPossibleObservation: NSKeyValueObservation?
    private var frameSizeObservation: NSKeyValueObservation?
    private var refreshIntervalTimer: Timer!

    private func initialize() {
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 10.0, *) {
            try! session.setCategory(.playback, mode: .moviePlayback)
        } else {
            // Fallback on earlier versions
        }
        try! session.setActive(true)
        setupVideoLayerView()
    }

    /// Starts PinP.
    /// Also, this function should be called due to a user operation. (This is a limitation of iOS app.)
    /// Every withRefreshInterval (in seconds), the screen will refresh the PiP video image.
    open func startPictureInPicture(
        withRefreshInterval: TimeInterval
    ) {
        initialize()
        DispatchQueue.main.async { [weak self] in
            self?.startPictureInPictureSub(refreshInterval: withRefreshInterval)
        }
    }

    /// Starts PinP.
    /// Also, this function should be called due to a user operation. (This is a limitation of iOS app.)
    /// This function will not automatically update the video image. You should call the render() function.
    open func startPictureInPictureWithManualCallRender() {
        initialize()
        DispatchQueue.main.async { [weak self] in
            self?.startPictureInPictureSub(refreshInterval: nil)
        }
    }

    private func startPictureInPictureSub(
        refreshInterval: TimeInterval?
    ) {
        if UIPiPView.isUIPiPViewSupported(), #available(iOS 15.0, *) {
            render() /// For initial display

            if (pipController == nil) {
                pipController = .init(contentSource: .init(
                    sampleBufferDisplayLayer: pipBufferDisplayLayer,
                    playbackDelegate: self))
                pipController?.delegate = self
            }

            guard let pipController = pipController else { return }
            if (pipController.isPictureInPicturePossible) {

                /// Start asynchronously after processing is complete
                /// (will not work if run here synchronously)
                DispatchQueue.main.async { [weak self] in
                    pipController.startPictureInPicture()
                    if let ti = refreshInterval {
                        self?.setRenderInterval(ti)
                    }
                }

            } else {
                /// It will take some time for PiP to become available.
                pipPossibleObservation = pipController.observe(
                    \AVPictureInPictureController.isPictureInPicturePossible,
                    options: [.initial, .new]) { [weak self] _, change in
                    guard let self = self else { return }

                    if (change.newValue ?? false) {
                        pipController.startPictureInPicture()
                        self.pipPossibleObservation = nil
                        if let ti = refreshInterval {
                            self.setRenderInterval(ti)
                        }
                    }
                }
            }
        } else {
            print("[UIPiPView] UIPiPView cannot be used on this device or OS.")
        }
    }

    private let videoLayerView = UIView()

    /// Since PinP requires a layer with the video on the screen, prepare a View.
    private func setupVideoLayerView() {
        if (videoLayerView.superview == nil) {

            self.addSubview(videoLayerView)
            self.sendSubviewToBack(videoLayerView)
            videoLayerView.frame = self.bounds
            videoLayerView.alpha = 0

            pipBufferDisplayLayer.frame = videoLayerView.bounds
            pipBufferDisplayLayer.videoGravity = .resizeAspect
            videoLayerView.layer.addSublayer(pipBufferDisplayLayer)

            /// If the frame size changes, follow it.
            frameSizeObservation = self.observe(
                \UIPiPView.frame, options: [.initial, .new]) { [weak self] _, _ in
                guard let self = self else { return }
                self.videoLayerView.frame = self.bounds
            }
        }
    }

    /// Stop PiP.
    open func stopPictureInPicture() {
        guard let pipController = pipController else { return }
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        }
        if refreshIntervalTimer != nil {
            refreshIntervalTimer.invalidate()
            refreshIntervalTimer = nil
        }
    }

    /// Returns whether PiP is running or not.
    open func isPictureInPictureActive() -> Bool {
        guard let pipController = pipController else { return false }
        return pipController.isPictureInPictureActive
    }

    // MARK: VideoProducer

    /// Draws the current UIView state as a video.
    /// Note that the PiP image will not change unless this function is called.
    open func render() {
        /// Occasionally occurs in the background
        if (pipBufferDisplayLayer.status == .failed) {
            pipBufferDisplayLayer.flush()
        }
        guard let buffer = makeNextVieoBuffer() else { return }
        pipBufferDisplayLayer.enqueue(buffer)
    }

    /// Call render periodically.
    /// If you have been calling render manually and
    /// want to change to using Timer to call render, use this function.
    open func setRenderInterval(
        _ interval: TimeInterval
    ) {
        if #available(iOS 10.0, *) {
            refreshIntervalTimer = Timer(
                timeInterval: interval, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.render()
                }
        } else {
            // Fallback on earlier versions
        }
        RunLoop.main.add(refreshIntervalTimer, forMode: .default)
    }

    /// Create and return a CMSampleBuffer.
    /// This function basically does not need to be called by UIPiPView users,
    /// but if you want to create your own modified CMSampleBuffer, prepare an overwritten function.
    open func makeNextVieoBuffer() -> CMSampleBuffer? {
        return self.makeSampleBuffer()
    }

    // MARK: AVPictureInPictureControllerDelegate
    open func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
    }

    open func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
    }

    /// Always call the parent when overriding this function.
    open func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        refreshIntervalTimer?.invalidate()
        refreshIntervalTimer = nil
    }

    // MARK: AVPictureInPictureSampleBufferPlaybackDelegate
    open func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
    }

    open func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        return CMTimeRange(
            start: .negativeInfinity,
            duration: .positiveInfinity
        )
    }

    open func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        return false
    }

    open func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
    }

    open func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
