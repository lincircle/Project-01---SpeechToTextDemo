//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Yuhsuan Lin on 2016/9/29.
//  Copyright © 2016年 me.cgua.speechtotext. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet var text_view: UITextView!
    @IBOutlet var microphone_button: UIButton!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    @IBAction func microphoneTapped(_ sender: AnyObject){
    
        if audioEngine.isRunning{
            
            audioEngine.stop()
            
            recognitionRequest?.endAudio()
            
            microphone_button.isEnabled = false
            
            microphone_button.setTitle("Start Recording", for: .normal)
        }
        else{
            
            startRecording()
            
            microphone_button.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available {
            
            self.microphone_button.isEnabled = true
        }
        else{
          
            self.microphone_button.isEnabled = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphone_button.isEnabled = false
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
                
            case .authorized:
                
                isButtonEnabled = true
                
            case .denied:
                
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .notDetermined:
                
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
                
            case .restricted:
                
                isButtonEnabled = false
                print("isButtonEnabled = false")
            }
            
            OperationQueue.main.addOperation {
                
                self.microphone_button.isEnabled = isButtonEnabled
                
            }
            
        }
        
    }
    
    func startRecording() {
        
        if recognitionTask != nil {     //任務是否處於運行狀態
            
            recognitionTask?.cancel()
            recognitionTask = nil
            
        }
        
        let audioSeession = AVAudioSession.sharedInstance()   //建立 audioSession 用於錄音
        
        do{
            
            try audioSeession.setCategory(AVAudioSessionCategoryRecord)    //設定 audioSession 變數
            try audioSeession.setMode(AVAudioSessionModeMeasurement)      //但因為進行設置可能會出現異常狀況，所以用try catch
            try audioSeession.setActive(true, with: .notifyOthersOnDeactivation)
            
        }
        catch{
            
            print("audioSession properties weren't set because of an error.")
            
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //初始化 recognitionRequest 變數，將錄音數據轉發給蘋果伺務器
        
        guard let inputNode = audioEngine.inputNode else {   //檢查iphone是否有有效的錄音設備
            
            fatalError("Audio engine has no input node")
            
        }
        
        guard let recognitionRequest = recognitionRequest else {  //檢查是否初始化成功
            
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            
        }
        
        recognitionRequest.shouldReportPartialResults = true  //在用戶說話的同時，將識別結果分批返回
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            //呼叫 speechRecognizer 裡的recognitionTask 方法開始識別 方法參數中包括一個處理函數
            
            var isFinal = false //定義 isfinal 函數，是否結束
            
            if result != nil {  //如果result是最終譯稿，將tableview text 設置為 result 音譯
                
                self.text_view.text = result?.bestTranscription.formattedString
                
                isFinal = (result?.isFinal)!
                
            }
            
            if error != nil || isFinal {  //表示 此段錄音已經結束
                
                self.audioEngine.stop()
                
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil  //終止物件
                
                self.recognitionTask = nil
                
                self.microphone_button.isEnabled = true  //錄音按鍵又可以按
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { (buffer, when) in
            
            self.recognitionRequest?.append(buffer)
            
        })
            
            audioEngine.prepare()
            
            do {
            
                try audioEngine.start()
            
            }
            catch{
                
                print("audioEngine couldn't start because of an error.")
            
            }
        
        
        text_view.text = "Say something, I'm listening!"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

