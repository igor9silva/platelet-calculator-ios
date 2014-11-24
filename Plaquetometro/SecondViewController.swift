//
//  SecondViewController.swift
//  Better Transf
//
//  Created by Igor Silva on 11/21/14.
//  Copyright (c) 2014 GARRA Software House. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITextFieldDelegate
{
    // IBOutlets
    @IBOutlet weak var txtPlaquetometriaInicial: UITextField!
    @IBOutlet weak var txtPlaquetometriaFinal: UITextField!
    @IBOutlet weak var txtPeso: UITextField!
    @IBOutlet weak var txtVolume: UITextField!
    @IBOutlet weak var ctrlTipoPessoa: UISegmentedControl!
    @IBOutlet weak var ctrlUnidadePeso: UISegmentedControl!
    @IBOutlet weak var ctrlTipoBolsa: UISegmentedControl!
    @IBOutlet weak var rsltBox: UITextField!
    
    // Constants
    var txt_max_length = [2,3,3,4] // PlaqInicial, PlaqFinal, Peso, Volume
    
    // viewDidLoad
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Setting txtFields delegates to self, so we can apply maximum length ----------------------------------------------------
        txtPlaquetometriaInicial.delegate = self
        txtPlaquetometriaFinal.delegate = self
        txtVolume.delegate = self
        txtPeso.delegate = self
        // ------------------------------------------------------------------------------------------------------------------------
        
        // Add 'done' button to txtFields -----------------------------------------------------------------------------------------
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Bordered, target: self, action: "doneClicked")
        keyboardDoneButtonView.setItems([doneButton], animated: true)
        
        txtPlaquetometriaInicial.inputAccessoryView = keyboardDoneButtonView
        txtPlaquetometriaFinal.inputAccessoryView = keyboardDoneButtonView
        txtPeso.inputAccessoryView = keyboardDoneButtonView
        txtVolume.inputAccessoryView = keyboardDoneButtonView
        // ------------------------------------------------------------------------------------------------------------------------

        // Show "missing data"
        ClearResult()
    }
    
    // 'done' button (on numPad keyboard) pressed
    func doneClicked()
    {
        // hide the keyboard
        self.view.endEditing(true)
    }
    
    // TextFields - shouldChangeCharactersInRange - applying the max length
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        // create a charset containing only numbers
        let charSet = NSCharacterSet(charactersInString: "0123456789")
        
        // check if all 'new characters' are numbers, return false if some of them aren't
        for i in 0..<countElements(string) {
            let c:unichar = (string as NSString).characterAtIndex(i)
            if (!charSet.characterIsMember(c)) {
                return false
            }
        }
        
        // return true if newLength <= maxLength, else return false
        return (countElements(textField.text) + countElements(string) - range.length < txt_max_length[textField.tag] + 1)
    }
    
    // Clear the results fields
    func ClearResult()
    {
        rsltBox.text = NSLocalizedString("MISSING_DATA", comment: "Missing some parameter, can't calculate results")
    }
    
    // Calculate result and show
    func CalculateAndShow()
    {
        // DIFERENÇA DE PLAQUETAS ------------------------------------------------------------
        var qtDiferencaPlaquetas:Double = 0
        if (countElements(txtPlaquetometriaInicial.text) > 0) {
            
            if (countElements(txtPlaquetometriaFinal.text) > 0) {
                qtDiferencaPlaquetas = Double(txtPlaquetometriaFinal.text.toInt()! - txtPlaquetometriaInicial.text.toInt()!) * 1000
            }
            else {
                ClearResult()
                return
            }
        }
        else {
            ClearResult()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // VOLEMIA ---------------------------------------------------------------------------
        var volemia:Double = 0;
        if (ctrlTipoPessoa.selectedSegmentIndex != UISegmentedControlNoSegment) {
            
            let volemiaPorKg = [75, 65, 90, 110]
            var PesoDouble:Double = 0
            
            if (countElements(txtPeso.text) > 0) {
                
                PesoDouble = Double(txtPeso.text.toInt()!)
                if (ctrlUnidadePeso.selectedSegmentIndex != UISegmentedControlNoSegment) {
                    
                    if (ctrlUnidadePeso.selectedSegmentIndex == 1) { // POUNDS
                        PesoDouble = PesoDouble / 2.2
                    }
                    else if (ctrlUnidadePeso.titleForSegmentAtIndex(0) == "g") { // GRAMAS (not kg)
                        PesoDouble /= 1000
                    }
                    
                }
                else {
                    ClearResult()
                    return
                }
                
            }
            else {
                ClearResult()
                return
            }
            
            volemia = PesoDouble * Double(volemiaPorKg[ctrlTipoPessoa.selectedSegmentIndex])
        }
        else {
            ClearResult()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // VOLUME DAS PLAQUETAS --------------------------------------------------------------
        
        var volume:Double = 0
        if (countElements(txtVolume.text) > 0) {
            if (ctrlTipoBolsa.selectedSegmentIndex != UISegmentedControlNoSegment) {
                
                volume = Double(txtVolume.text.toInt()!)
                // 0 = Standard | 1 = Aferese
                volume *= ctrlTipoBolsa.selectedSegmentIndex == 0 ? 1_000_000_000 : 1_500_000_000
                
            }
            else {
                ClearResult()
                return
            }
        }
        else {
            ClearResult()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // APLICANDO A FÓRMULA ---------------------------------------------------------------
        let rendimento:Double = (Double(qtDiferencaPlaquetas) * volemia * 1000) / volume
        // -----------------------------------------------------------------------------------
        
        // EXIBINDO --------------------------------------------------------------------------
        rsltBox.text = NSString(format: "%.0f%%", rendimento * 100)
        // -----------------------------------------------------------------------------------
    }
    
    // IBActions ------------------------------------------------------------------------------------------------------------------
    @IBAction func ctrlTipoPessoa_ValueChanged(sender: UISegmentedControl)
    {
        if (sender.selectedSegmentIndex > 1) {
            // set maxLength for 'g'
            ctrlUnidadePeso.setTitle("g", forSegmentAtIndex: 0)
            if (ctrlUnidadePeso.selectedSegmentIndex == 0) {
                txt_max_length[2] = 4
            }
        }
        else {
            // set maxLength for 'kg'
            ctrlUnidadePeso.setTitle("kg", forSegmentAtIndex: 0)
            txt_max_length[2] = 3
            
            // If have more then maxLength caracters, delete the extra ones
            if (countElements(txtPeso.text) > txt_max_length[2]) {
                let i = advance(txtPeso.text.startIndex, txt_max_length[2])
                txtPeso.text = txtPeso.text.substringToIndex(i)
            }
        }
        
        CalculateAndShow()
    }
    
    @IBAction func ctrlUnidadePeso_ValueChanged(sender: UISegmentedControl)
    {
        if (sender.selectedSegmentIndex == 0) {
            // set maxLength for 'g'
            if (sender.titleForSegmentAtIndex(0) == "g") {
                txt_max_length[2] = 4
            }
        }
        else {
            // set maxLength for 'kg'
            txt_max_length[2] = 3
            
            // If have more then maxLength caracters, delete the extra ones
            if (countElements(txtPeso.text) > txt_max_length[2]) {
                let i = advance(txtPeso.text.startIndex, txt_max_length[2])
                txtPeso.text = txtPeso.text.substringToIndex(i)
            }
        }
        
        CalculateAndShow()
    }
    
    @IBAction func ctrlTipoBolsa_ValueChanged(sender: UISegmentedControl)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtPlaquetometriaInicial_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtPlaquetometriaFinal_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtPeso_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtVolume_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func test()
    {
        
    }
    // ----------------------------------------------------------------------------------------------------------------------------
}