import UIKit
import Particle_SDK

class ViewController: UIViewController
{
    // MARK: User variables
    let USERNAME = "carlosbulado@gmail.com"
    let PASSWORD = "C4rl0sParticle"
    var randomShape = 0
    var totalCorrect = 0
    var totalTries = 0
    // MARK: Device
    let DEVICE_ID = "220038000447363333343435"
    var myPhoton : ParticleDevice?
    //MARK: IBOutlets
    @IBOutlet weak var shapeLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var shapesNumberLabel: UILabel!
    @IBOutlet weak var newShapeBtn: UIButton!
    @IBOutlet weak var switchGameOpt: UISwitch!
    @IBOutlet weak var imgShape: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // 1. Initialize the SDK
        ParticleCloud.init()
        
        // 2. Login to your account
        ParticleCloud.sharedInstance().login(withUser: self.USERNAME, password: self.PASSWORD)
        {
            (error:Error?) -> Void in
            if (error != nil)
            {
                // Something went wrong!
                print("Wrong credentials or as! ParticleCompletionBlock no internet connectivity, please try again")
                // Print out more detailed information
                print(error?.localizedDescription)
            }
            else
            {
                print("Login success!")

                // try to get the device
                self.getDeviceFromCloud()
            }
        } // end login
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Get Device from Cloud
    // Gets the device from the Particle Cloud
    // and sets the global device variable
    func getDeviceFromCloud()
    {
        ParticleCloud.sharedInstance().getDevice(self.DEVICE_ID) { (device:ParticleDevice?, error:Error?) in
            
            if (error != nil)
            {
                print("Could not get device")
                print(error?.localizedDescription)
                return
            }
            else
            {
                print("Got photon from cloud: \(device!.id)")
                self.myPhoton = device
                
                // subscribe to events
                self.subscribeToParticleEvents()
            }
            
        } // end getDevice()
    }
    
    
    //MARK: Subscribe to "playerChoice" events on Particle
    func subscribeToParticleEvents()
    {
        ParticleCloud.sharedInstance().subscribeToDeviceEvents(
            //withPrefix: "sideShape",
            withPrefix: nil,
            deviceID:self.DEVICE_ID,
            handler: {
                (event :ParticleEvent?, error : Error?) in
            
            if let _ = error {
                print("could not subscribe to events")
            } else {
                print("got event with data \(event)")
                let choice = (event?.data)!
                switch(event?.event)
                {
                    case "totalCorrect":
                        self.totalCorrect = Int(choice)!
                        self.setScore()
                    case "totalTries":
                        self.totalTries = Int(choice)!
                        self.setScore()
                    default:
                        if (self.randomShape == Int(choice))
                        {
                            self.correctAnswer()
                        }
                        else
                        {
                            self.incorrectAnswer()
                        }
                }
            }
        })

        self.generateShape()
    }

    //MARK: IBActions
    @IBAction func changeSideNumber(_ sender: Any)
    {
        self.generateShape()
    }
    
    @IBAction func changeGame(_ sender: Any)
    {
        self.generateShape()
    }
    
    @IBAction func decideGame(_ sender: Any)
    {
        let r = Int.random(in: 1 ... 11)
        self.switchGameOpt.isOn = r % 2 == 0
        self.generateShape()
    }
    
    //MARK: Class custom functions
    func callParticleFunc(functionName: String, arg: [String])
    {
        myPhoton!.callFunction(functionName, withArguments: arg) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) { }
        }
    }
    
    func generateShape()
    {
        self.randomShape = Int.random(in: 3 ... 4)
        if !self.switchGameOpt.isOn
        {
//            self.shapeLabel.text = "Number of shapes: \(self.randomShape)"
            self.shapeLabel.text = ""
            self.shapesNumberLabel.text = "How many sides does this shape have? .... Waiting for particle"
            self.imgShape.isHidden = false
            switch(self.randomShape)
            {
                case 4:
                    self.imgShape.image = UIImage.init(named: "square")
                default:
                    self.imgShape.image = UIImage.init(named: "triangle")
            }
            
            self.callParticleFunc(functionName: "howManyShapes", arg: ["\(self.randomShape)"])
            self.newShapeBtn.isHidden = true
        }
        else
        {
            self.randomShape = Int.random(in: 1 ... 3)
            self.shapeLabel.text = "Draw the shape \(self.randomShape)"
            self.imgShape.isHidden = true
            self.shapesNumberLabel.text = ""
            self.callParticleFunc(functionName: "shapeNumber", arg: ["\(self.randomShape)"])
            self.newShapeBtn.isHidden = true
        }
    }
    
    func correctAnswer()
    {
        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                // now update UI on main thread
                self.shapesNumberLabel.text = "CORRECT!"
                self.callParticleFunc(functionName: "color", arg: ["green"])
                self.newShapeBtn.isHidden = false
                self.imgShape.isHidden = true
            }
        }
    }
    
    func incorrectAnswer()
    {
        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                // now update UI on main thread
                self.shapesNumberLabel.text = "INCORRECT!"
                self.callParticleFunc(functionName: "color", arg: ["red"])
                self.newShapeBtn.isHidden = false
                self.imgShape.isHidden = true
            }
        }
    }
    
    func setScore()
    {
        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                // now update UI on main thread
                self.scoreLabel.text = " Score: \(self.totalCorrect) / \(self.totalTries)"
            }
        }
    }
}
