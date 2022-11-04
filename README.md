# MyPipApp
画中画的介绍，如何使用画中画实现计时器，如何使用画中画实现每日英语听力效果

[我的博客](https://morganwang.cn/)

## 背景

之前有看到有人用画中画实现时分秒的计时，顺手收藏了，一直没来及看。最近使用《每日英语听力》，突然发现它用画中画实现了听力语句的显示，顿时来了兴趣，所以来研究一下是怎么实现的？顺便也研究下画中画时分秒计时的实现——每次遇到某些平台每天固定时间开抢的时候，我都希望iPhone能够显示具体到秒的计时，这样就能知道什么时候开始点击合适，而不是每次都提前一分钟在那里不停的点点点却什么都抢不到。。。

<!--more-->


## 实现

就像大家都知道的，画中画是用来浮窗播放视频的，所以下面分为几步来分析：
- 首先来看下，实现画中画功能，需要设置哪些开关，实现哪些方法；
- 然后来看下，基本的使用系统播放器时，画中画的实现；
- 然后再来看下，自定义播放器时，画中画功能的实现又需要如何设置，有哪些不同；
- 再然后来看如何通过画中画实现时分秒计时功能；
- 最后再来看，《每日英语听力》通过画中画播放英语听力语句时怎么实现的？

### APP支持画中画功能

如何让APP支持画中画功能？首先需要设置App支持`BackgroundModes`，然后勾选`BackgroundModes`中的`Audio, Airplay, and Picture in Picture`。

操作如下：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/Xnip2022-08-13_09-16-33.jpg" width="70%">

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/Xnip2022-08-13_09-18-32.jpg" width="70%">

然后需要设置`AVAudioSession`，在`AppDelegate.Swift`中`application(_:didFinishLaunchingWithOptions:)`方法设置如下代码：

1. 导入`AVFoundation`
2. 设置`AVAudioSession`支持后台播放

``` Swift

// 导入AVFoundation
import AVFoundation

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 添加设置代码
        do {
            // 设置AVAudioSession.Category.playback后，在静音模式下，或者APP进入后台，或者锁定屏幕后还可以继续播放。
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback)
        } catch {
            print(error)
        }

        return true
    }

```

### 使用系统播放器时画中画的实现

使用系统播放器`AVPlayerViewController`来实现播放器画中画，首先导入`AVKit`，获取要播放的资源，然后使用`AVPlayerViewController`来进行播放，代码如下：

``` Swift
import AVKit

    /// 获取播放的资源
    fileprivate func playerResource() -> AVQueuePlayer? {
        guard let videoURL = Bundle.main.url(forResource: "suancaidegang", withExtension: "mp4") else {
          return nil
        }

        let item = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer(playerItem: item)
        player.actionAtItemEnd = .pause
        return player
    }

    @IBAction func systemPlayerAction(_ sender: Any) {
        guard let player = playerResource() else {
            return
        }
        let avPlayerVC = AVPlayerViewController()
        avPlayerVC.player = player
        present(avPlayerVC, animated: true) {
            player.play()
        }
    }

```

这里需要注意的是，一定要在真机上才可以看到画中画的效果，使用模拟器不行。运行后可以看到`AVPlayerViewController`直接支持了画中画的播放；点击进入画中画后，之前全屏的播放界面自动关掉；点击画中画返回播放界面后，画中画关闭，但是之前的播放界面也没有重新打开，效果如下：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/AVPlayerViewController%E6%B2%A1%E8%AE%BE%E7%BD%AE%E6%97%B6%E6%95%88%E6%9E%9C.gif" height="500px">

而这里很明显，画中画返回不了之前的播放界面是有问题的，所以要修改一下，加入可以设置再进入画中画时全屏的播放界面不关闭，点击画中画的返回是否可以正常呢？这里`AVPlayerViewControllerDelegate`的方法` playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool`可以控制进入画中画时是否关闭当前界面。

``` Swift
    // 在此方法中添加avPlayerVC.delegate = self
    @IBAction func systemPlayerAction(_ sender: Any) {
        guard let player = playerResource() else {
            return
        }
        let avPlayerVC = AVPlayerViewController()
        avPlayerVC.delegate = self
        avPlayerVC.player = player
        present(avPlayerVC, animated: true) {
            player.play()
        }
    }

    // 设置AVPlayerViewControllerDelegate
   extension ViewController: AVPlayerViewControllerDelegate {
       func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
            // 返回false时，进入画中画后播放界面不关闭
            // 返回true时，进入画中画后播放界面自动关闭，默认为true
           return false
       }
   }

```

运行调试效果，可以看到，进入画中画时，播放界面没关闭，显示`This video is playing in picture in picture`，且没有关闭按钮；画中画返回时，播放界面可以继续接着播放。效果如下：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/AVPlayer%E8%AE%BE%E7%BD%AE%E6%95%88%E6%9E%9C.gif" height="500px">

但是上面的效果也不是所期望的，因为通常进入画中画模式，是为了继续操作页面其他的内容，而上面的设置虽然可以让画中画返回时继续播放，但是却也阻碍了操作页面其他的内容，所以还是需要修改。希望实现的效果是，进入画中画界面，当前播放界面消失；并且从画中画返回时，还可以进入播放界面，下面来看下如何设置实现：

在`AVPlayerViewControllerDelegate`中有另外一个方法`playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) `，画中画点击返回时会触发这个方法，所以要做的内容是，在这个方法被触发时，重新唤起播放视频界面，代码如下：

``` Swift

extension ViewController: AVPlayerViewControllerDelegate {
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        // 这里修改为返回true，即进入画中画时关闭播放界面
        return true
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restore(playerVC: playerViewController, completionHandler: completionHandler)
    }
}

    fileprivate func restore(playerVC: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        if let presentedVC = presentedViewController {
            // 说明当前正在播放的界面还存在
            // 先关闭界面，再弹出播放界面
            presentedVC.dismiss(animated: false) { [weak self] in
                self?.present(playerVC, animated: false) {
                    completionHandler(true)
                }
            }
        } else {
            // 直接弹出播放界面
            present(playerVC, animated: false) {
                completionHandler(true)
            }
        }
    }

```

运行查看效果，可以看到进入画中画界面，当前播放界面消失；并且从画中画返回时，还可以进入播放界面，完美。演示如下：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/AVPlayer%E6%9C%80%E7%BB%88%E6%95%88%E6%9E%9C.gif" height="500px">

### 自定义播放器时画中画的实现

自定义播放器相比于使用系统的`AVPlayerViewController`，需要在自定义播放器界面实现点击唤起画中画播放，并且实现画中画的代理方法`AVPictureInPictureControllerDelegate`，在画中画的代理方法中，处理画中画返回时的逻辑。需要着重注意的是，如果设置进入画中画后播放界面消失，则当前的播放界面会被释放掉，会导致播放界面上的画中画播放也会消失，所以需要特殊处理下，声明一个全局的<Set>来存储。参考[Picture in Picture Across All Platforms](https://www.raywenderlich.com/24247382-picture-in-picture-across-all-platforms)。

代码大致如下：

``` Swift

protocol CustomPlayerVCDelegate: AnyObject {
    func playerViewController(
      _ playerViewController: MWCustomPlayerVC,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
        completionHandler: @escaping (Bool) -> Void
    )
}

private var activeCustomPlayerVCs = Set<MWCustomPlayerVC>()
class MWCustomPlayerVC: UIViewController {

    // MARK: - properties
    private var pictureInPictureVC: AVPictureInPictureController?
    weak var delegate: CustomPlayerVCDelegate?
    var autoDismissAtPip: Bool = false // 进入画中画时，是否自动关闭当前播放页面
    var enterPipBtn: CustomPlayerCircularButtonView?

   override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .black
        
        setupPictureInPictureVC()
        setupEnterPipBtn()
    }

   fileprivate func setupPictureInPictureVC() {
        guard let playerLayer = playerLayer else {
            return
        }

        pictureInPictureVC = AVPictureInPictureController(playerLayer: playerLayer)
        pictureInPictureVC?.delegate = self
    }
       
    fileprivate func setupEnterPipBtn() {
        enterPipBtn = CustomPlayerCircularButtonView(symbolName: "pip.enter", height: 50.0)
        enterPipBtn?.addTarget(self, action: #selector(handleEnterPipAction), for: [.primaryActionTriggered, .touchUpInside])
        view.addSubview(enterPipBtn!)
        
        enterPipBtn?.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(10.0)
            make.centerY.equalTo(self.view.snp.centerY)
            make.width.height.equalTo(50.0)
        }
    }

    // 点击唤起画中画界面
    @objc
    fileprivate func handleEnterPipAction() {
        pictureInPictureVC?.startPictureInPicture()
    }
}

extension MWCustomPlayerVC: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // 进入画中画播放的代理方法
        activeCustomPlayerVCs.insert(self)
        enterPipBtn?.isHidden = true
    }
    
    // 画中画开始播放后，当前播放界面是否消失
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if autoDismissAtPip {
            dismiss(animated: true)
        }
    }
    
    // 画中画进入失败
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        activeCustomPlayerVCs.remove(self)
        enterPipBtn?.isHidden = false
    }
    
    // 画中画返回的代理方法
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        delegate?.playerViewController(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }
}

```

然后在外面使用的地方调用，并且处理画中画关闭的回调代理方法，如下：

``` Swift

    @IBAction func customPlayerAction(_ sender: Any) {
        guard let player = playerResource() else {
            return
        }
        
        let playerVC = MWCustomPlayerVC()
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.delegate = self
        playerVC.player = player
        playerVC.autoDismissAtPip = true
        present(playerVC, animated: true) {
            player.play()
        }
    }

 extension ViewController: CustomPlayerVCDelegate {
    func playerViewController(
      _ playerViewController: MWCustomPlayerVC,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
      completionHandler: @escaping (Bool) -> Void) {
          restore(playerVC: playerViewController, completionHandler: completionHandler)
      }
}

```

运行后效果如下，可以看到，自定义的播放器处理后可以和系统自带播放器的画中画效果一样：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/%E8%87%AA%E5%AE%9A%E4%B9%89%E6%92%AD%E6%94%BE%E5%99%A8%E7%94%BB%E4%B8%AD%E7%94%BB.gif" height="500px">


在开始下一步之前，希望大家能思考一下：通过上面的画中画例子，已经知道画中画是怎么使用的了。那假如让你来实现一个画中画的计时，你会怎么实现，有哪些方法？

- 笔者想的方法是，既然画中画是播放视频的，那是否可以把view转为视频？然后再用播放视频的方式，来播放view的内容？
- 然后笔者查阅了网上其他资料，发现还有一种更tricky的思路，既然画中画在APP中弹出，那是不是能获取画中画的window，获取到window之后，直接在window上添加view的显示是不是就可以了？

下面就依次来验证一下这两种方法是否都可行？
首先画中画的计时，就来验证方法一是否可行；《每日英语听力》语句的展示，来验证方法二是否可行。

### 时分秒计时画中画的实现

这里使用方法一，即把view转为视频，再用播放视频的方式来播放view的内容，来实现一个计时器。那么问题是如何把view转为视频？

咱也不知道，也搜不到直接的转换方法，但是参考[UIPiPView](https://github.com/uakihir0/UIPiPView)，可以发现里面是把`view`转为`CMSampleBuffer`（参考https://soranoba.net/programming/uiview-to-cmsamplebuffer），通过`initWithSampleBufferDisplayLayer`方法用`AVSampleBufferDisplayLayer`来初始化`AVPictureInPictureController.ContentSource`，再用`AVPictureInPictureController.ContentSource`来初始化`AVPictureInPictureController`，然后用`AVSampleBufferDisplayLayer`来展示`CMSampleBuffer`，binggo，于是就把view显示在了`AVPictureInPictureController`上。

这里需要注意的又一个问题是，上面的把`view`转为`CMSampleBuffer`，再把`CMSampleBuffer`显示到`AVPictureInPictureController`上的过程只是单个view，而如何变成一个流畅的视频播放呢？答案是定义不断的刷新timer，那刷新的timer的间隔多少合适呢？肉眼看不到卡顿就合适，`UIPiPView`中推荐使用0.1/60秒。

这里就不再重复封装，直接使用[UIPiPView](https://github.com/uakihir0/UIPiPView)，然后创建一个计时器，需要注意的是要显示的view是添加在`UIPipView`上。

代码如下：

``` Swift

import UIKit
import UIPiPView
import SnapKit

class MWFullTimerVC: MWBaseVC {
    
    // MARK: - properties
    private let pipView = UIPiPView()
    private let timeLabel = UILabel()
    private let dateFormatStr = "yyyy-MM-dd HH:mm:ss"
    private var timer: Timer?

    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        
        setupPipView()
        setupTimeLabel()
        createDisplayLink()
    }
    
    fileprivate func setupPipView() {
        let width = UIScreen.main.bounds.width
        pipView.frame = CGRect(x: 10.0, y: 0, width: width - 20.0, height: 50.0)
        view.addSubview(pipView)
        pipView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10.0)
            make.top.equalToSuperview().inset(100.0)
            make.height.equalTo(50.0)
        }
    }
    
    fileprivate func setupTimeLabel() {
        timeLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        timeLabel.textColor = UIColor.white
        timeLabel.backgroundColor = UIColor.orange
        timeLabel.textAlignment = .center
        pipView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    func createDisplayLink() {
        timer = Timer(timeInterval: 0.1/60, repeats: true, block: { [weak self] _ in
            self?.refresh()
        })
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        timer?.fire()
    }

    
    // MARK: - init
    
    
    // MARK: - utils
    func reloadTime() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormatStr
        self.timeLabel.text = formatter.string(from: date)
    }

    
    // MARK: - action
    
    func refresh() {
        reloadTime()
    }
    
    override func handleEnterPipAction() {
        super.handleEnterPipAction()
        if pipView.isPictureInPictureActive() {
            pipView.stopPictureInPicture()
        } else {
            pipView.startPictureInPicture(withRefreshInterval: 0.1/60.0)
        }
    }
    
    // MARK: - other
  
}

```

运行后调试效果如下：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/UIPipView.gif" height="500px">

可以看到上面的方法是可行的，而且画中画的大小是可自己定义的，同时不需要内置空白的视频文件。定义的视图什么样画中画的显示就是什么样。


### 《每日英语听力》画中画的实现

这里来验证获取画中画的window，获取到window后直接在window上添加view的显示，从而在画中画中显示自定义view的方式。

在画中画即将展示的代理方法`pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController)`中，获取到最上层window，然后添加自定义文字播放view。文字播放view设置每隔2秒播放下一句。

最终整体代码如下：

``` Swift
class MWPipWindowVC: UIViewController {
    func setupTextPlayerView(on targetView: UIView) {
        targetView.addSubview(textPlayView)
        textPlayView.text = text1
        
        textPlayView.snp.makeConstraints { make in
            make.centerY.equalTo(targetView.snp.centerY)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250.0)
        }
    }

       fileprivate func setupTimer() {
        timer = Timer(timeInterval: 2.0, repeats: true, block: { [weak self] _ in
            self?.handleTimerAction()
        })
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        timer?.fire()
    }

    // MARK: - utils
    
    // MARK: - action
    func handleTimerAction() {
        let dataList = [text1, text2, text3, text4, text5]
        count += 1
        let index = count % 5
        let str = dataList[index]
        textPlayView.text = str
    }
  }

extension MWPipWindowVC: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        activeCustomPlayerVCs.insert(self)
        enterPipBtn?.isHidden = true
        if let window = UIApplication.shared.windows.first {
            setupTextPlayerView(on: window)
        }
    }
    xxx
}

```

运行调试，最终效果如下：

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/%E7%94%BB%E4%B8%AD%E7%94%BB%E6%92%AD%E6%94%BE%E6%96%87%E5%AD%97.gif" height="500px">

可以看到上面的方法是可行的，但是需要注意的是，这里进入画中画时可以看到播放视频的界面闪了一下，而且画中画的尺寸是和视频尺寸一致的。所以随用这种方法时，需要提前准备好对应尺寸的空白视频，然后使用画中画播放空白视频，再把自定义的view添加到画中画的window上。


## 总结

<img src="https://raw.githubusercontent.com/mokong/BlogImages/main/img/%E7%94%BB%E4%B8%AD%E7%94%BB.png" width="70%">


## 参考
- [Adopting Picture in Picture in a Standard Player](https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_standard_player)
- [Picture in Picture Across All Platforms](https://www.raywenderlich.com/24247382-picture-in-picture-across-all-platforms)
- [UIPiPView](https://github.com/uakihir0/UIPiPView)
- [CustomPictureInPicture](https://github.com/CaiWanFeng/CustomPictureInPicture/blob/master/pip_swift/pip_swift/ViewController.swift)
