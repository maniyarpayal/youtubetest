//
import GoogleAPIClientForREST
import GoogleSignIn
import UIKit
import GTMSessionFetcher // Allows to access GTLRYouTubeService.authorizer().
import MobileCoreServices


class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    private let scopes = [kGTLRAuthScopeYouTube,kGTLRAuthScopeYouTubeForceSsl, kGTLRAuthScopeYouTubeUpload,kGTLRAuthScopeYouTubeYoutubepartner]
    
    let service: GTLRYouTubeService = YouTubeServiceSingleton.sharedInstance()
    let signInButton = GIDSignInButton()
    let output = UITextView()
    
    var uploadTitleField = "Testing"
    var uploadPathField = ""
    var uploadFileTicket: GTLRServiceTicket?
    
    var uploadLocationURL : URL? = nil
    var progressbar : UIProgressView!
    @IBOutlet weak var selectVideoBtn : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fileManager = FileManager.default
        var _ : NSError?
        let doumentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let destinationPath = doumentDirectoryPath.appendingPathComponent("Hyperloop.mp4")
        let sourcePath = Bundle.main.path(forResource: "Hyperloop", ofType: "mp4")
        
        do{
            
            try fileManager.copyItem(atPath: sourcePath!, toPath: destinationPath)
        }
        catch _
        {
            print(Error.self);
        }
        
        uploadPathField = destinationPath
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        // Add the sign-in button.
        view.addSubview(signInButton)
        signInButton.center = self.view.center
        
        // Add a UITextView to display output.
//        output.frame = view.bounds
//        output.isEditable = false
//        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
//        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
//        output.isHidden = true
//        view.addSubview(output);
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            self.signInButton.isHidden = true
            self.output.isHidden = false
           
            self.service.authorizer = user.authentication.fetcherAuthorizer()
//            uploadClicked(signInButton)
        }
         self.selectVideoBtn.isHidden = !self.signInButton.isHidden
    }
    @IBAction func uploadBtnClicked(sender : UIButton)
    {
        let imagePicker : UIImagePickerController = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        self.present(imagePicker, animated: true) {
                    }
    }
    @IBAction func uploadClicked(_ sender: Any) {
        uploadVideoFile()
    }
    @IBAction func pauseUploadClicked(_ sender: Any) {
        if (uploadFileTicket?.isUploadPaused)! {
            // Resume from pause.
            uploadFileTicket?.resumeUpload()
        }
        else {
            // Pause.
            uploadFileTicket?.pauseUpload()
        }
    }
    @IBAction func stopUploadClicked(_ sender: Any) {
        uploadFileTicket?.cancel()
        uploadFileTicket = nil
    }
    @IBAction func restartUploadClicked(_ sender: Any) {
        restartUpload()
    }
    // MARK: - Upload
    func uploadVideoFile() {
        // Collect the metadata for the upload from the user interface.
        // Status.
        let status = GTLRYouTube_VideoStatus()
        status.privacyStatus = kGTLRYouTube_ChannelStatus_PrivacyStatus_Private//uploadPrivacyPopup.titleOfSelectedItem
        // Snippet.
        let snippet = GTLRYouTube_VideoSnippet()
        snippet.title = "\(uploadTitleField)"
        let desc = "This is demo of upload video on Youtube"
        if desc.count > 0 {
            snippet.descriptionProperty = desc
        }
        let tagsStr = ""
        if tagsStr.count > 0 {
            snippet.tags = tagsStr.components(separatedBy: ",")
        }

        let video = GTLRYouTube_Video()
        video.status = status
        video.snippet = snippet
        uploadVideo(withVideoObject: video, resumeUploadLocationURL: nil)
    }
    func restartUpload() {
        // Restart a stopped upload, using the location URL from the previous
        // upload attempt
        if uploadLocationURL == nil {
            return
        }
        // Since we are restarting an upload, we do not need to add metadata to the
        // video object.
        let video = GTLRYouTube_Video()
        uploadVideo(withVideoObject: video, resumeUploadLocationURL: uploadLocationURL)
    }
    func uploadVideo(withVideoObject video: GTLRYouTube_Video, resumeUploadLocationURL locationURL: URL?) {
        let fileToUploadURL = URL(fileURLWithPath: "\(uploadPathField)")
        if !(try! fileToUploadURL.checkPromisedItemIsReachable()) {
            return
        }
        // Get a file handle for the upload data.
        let filename: String? = fileToUploadURL.lastPathComponent
        let mimeType: String = self.mimeType(forFilename: filename!, defaultMIMEType: "video/mp4")
        let uploadParameters = GTLRUploadParameters(fileURL: fileToUploadURL, mimeType: mimeType)
        uploadParameters.uploadLocationURL = locationURL
        
        
        
        let query = GTLRYouTubeQuery_VideosInsert.query(withObject: video, part: "snippet,status", uploadParameters: uploadParameters)

       

      query.executionParameters.uploadProgressBlock = {(_ ticket: GTLRServiceTicket, _ numberOfBytesRead: UInt64, _ dataLength: UInt64) -> Void in
print ("total bytes = \(Double(dataLength))")
            print ("uploaded bytes = \(Double(numberOfBytesRead))")
        self.progressbar.progress = Float(Double(numberOfBytesRead)/Double(dataLength))
                    }
      
        uploadFileTicket = self.fetchChannelResource()
    }

    ///
    // List up to 10 files in Drive
    ///
    func fetchChannelResource() -> GTLRServiceTicket {
        let query = GTLRYouTubeQuery_ChannelsList.query( withPart: "snippet,statistics" )
        query.identifier = "UC_x5XG1OV2P6uZZ5FSM9Ttw"
        // To retrieve data for the current user's channel, comment out the previous
        // line (query.identifier ...) and uncomment the next line (query.mine ...)
        // query.mine = true
        return service.executeQuery( query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:)))

    }
    func mimeType(forFilename filename: String, defaultMIMEType defaultType: String) -> String {
        let result: String = defaultType
        return result
    }
    @objc func displayResultWithTicket(
        ticket: GTLRServiceTicket,
        finishedWithObject response : GTLRYouTube_Video,
        error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        self.hideProgressBar(self, completion: {
            self.showAlert(title: "Uploaded", message: "Uploaded file\(String(describing: response.snippet!.title))")
        })
        

    
    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
                preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(
            title: "OK",
                style: UIAlertAction.Style.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
        
//        MARK:- Image picker delegate methods
    func imagePickerController( _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any] ) {
        self.uploadPathField = ( info[UIImagePickerController.InfoKey.mediaURL] as! URL ).path
            self.dismiss(animated: true) {
                self.displayProgressBarWithProgress(0, sender: self)
                 self.uploadVideoFile()
               
            }
           
        }
    //        MARK:- Hide Show progressbar methhods
    func displayProgressBarWithProgress( _ progress: Float, sender: UIViewController ) {
        //create an alert controller
        let alertController = UIAlertController( title: "Processing...", message: "\n" + "Please stay in this screen...", preferredStyle: UIAlertController.Style.alert )
        
        self.progressbar = UIProgressView.init(progressViewStyle: .default)
        self.progressbar.center = CGPoint(x: 135.0, y: 100)
        let height: NSLayoutConstraint = NSLayoutConstraint( item: alertController.view,
                attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 150 )

        alertController.view.addConstraint(height);
        self.progressbar.progress = progress
        self.progressbar.tintColor =  UIColor.init(red: 2/255.0, green: 133/255.0, blue: 198/255.0, alpha: 1.0)
        alertController.view.addSubview(self.progressbar)
        sender.present(alertController, animated: false, completion: nil)
    }

    func displayProgressBarWithProgressAndReturn( _ progress: Float, sender: UIViewController ) -> ( UIProgressView ) {
        self.displayProgressBarWithProgress( progress, sender: sender )
        return self.progressbar;
    }
    
    func hideProgressBar(_ sender:UIViewController, completion : @escaping ()->()) {
        sender.dismiss(animated: true, completion: completion)
    }
}

