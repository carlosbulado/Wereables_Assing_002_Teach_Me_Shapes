import UIKit
import Particle_SDK

class ViewController: UIViewController
{
    // MARK: User variables
    let USERNAME = ""
    let PASSWORD = ""
    var randomShape = 0
    // MARK: Device
    let DEVICE_ID = ""
    var myPhoton : ParticleDevice?
    //MARK: IBOutlets
    @IBOutlet weak var shapeLabel: UILabel!
    @IBOutlet weak var shapesNumberLabel: UILabel!
    
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
        var handler : Any?
        handler = ParticleCloud.sharedInstance().subscribeToDeviceEvents(
            withPrefix: "sideShape",
            deviceID:self.DEVICE_ID,
            handler: {
                (event :ParticleEvent?, error : Error?) in
            
            if let _ = error {
                print("could not subscribe to events")
            } else {
                print("got event with data \(event?.data)")
                let choice = (event?.data)!
                if (self.randomShape == Int(choice))
                {
                    self.correctAnswer()
                }
                else
                {
                    self.incorrectAnswer()
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
    
    
    //MARK: Class custom functions
    func callParticleFunc(functionName: String, arg: [String])
    {
        myPhoton!.callFunction(functionName, withArguments: arg) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) { }
        }
    }
    
    func generateShape()
    {
        randomShape = Int.random(in: 1 ... 4)
        self.shapeLabel.text = "Number of shapes: \(randomShape)"
        self.shapesNumberLabel.text = "How many sides does this shape have?"
        self.callParticleFunc(functionName: "howManyShapes", arg: ["\(randomShape)"])
    }
    
    func correctAnswer()
    {
        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                // now update UI on main thread
                self.shapesNumberLabel.text = "CORRECT!"
            }
        }
    }
    
    func incorrectAnswer()
    {
        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                // now update UI on main thread
                self.shapesNumberLabel.text = "INCORRECT!"
            }
        }
    }
}
