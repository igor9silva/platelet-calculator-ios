//
//  FirstViewController.swift
//  Better Transf
//
//  Created by Igor Silva on 11/21/14.
//  Copyright (c) 2014 GARRA Software House. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, UITextFieldDelegate
{
    // IBOutlets
    @IBOutlet weak var txtPlaquetometria: UITextField!
    @IBOutlet weak var txtRendimento: UITextField!
    @IBOutlet weak var txtPeso: UITextField!
    @IBOutlet weak var ctrlUnidadePeso: UISegmentedControl!
    @IBOutlet weak var ctrlTipoPaciente: UISegmentedControl!
    @IBOutlet weak var ctrlTipoTransfusao: UISegmentedControl!
    @IBOutlet weak var rsltStandard: UITextField!
    @IBOutlet weak var rsltAferese: UITextField!
    
    // Constants
    var txt_max_length = [2, 2, 3] // Plaquetometria, Rendimento, Peso
    
    // viewDidLoad
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Setting txtFields delegates to self, so we can apply maximum length ----------------------------------------------------
        txtPlaquetometria.delegate = self
        txtRendimento.delegate = self
        txtPeso.delegate = self
        // ------------------------------------------------------------------------------------------------------------------------
        
        // Add 'done' button to txtFields -----------------------------------------------------------------------------------------
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Bordered, target: self, action: "doneClicked")
        keyboardDoneButtonView.setItems([doneButton], animated: true)
        
        txtPlaquetometria.inputAccessoryView = keyboardDoneButtonView
        txtRendimento.inputAccessoryView = keyboardDoneButtonView
        txtPeso.inputAccessoryView = keyboardDoneButtonView
        // ------------------------------------------------------------------------------------------------------------------------
        
        // Show "missing data"
        ClearResults()
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
        
        return (countElements(textField.text) + countElements(string) - range.length < txt_max_length[textField.tag] + 1)
    }
    
    // Clear the results fields
    func ClearResults()
    {
        rsltStandard.text = NSLocalizedString("MISSING_DATA", comment: "Missing some parameter, can't calculate results")
        rsltAferese.text = NSLocalizedString("MISSING_DATA", comment: "Missing some parameter, can't calculate results")
    }
    
    // Calculate results and show
    func CalculateAndShow()
    {
        // DIFERENÇA PLAQUETAS (quantidade desejada - quantidade atual) ----------------------

        var qtPlaquetasDesejadas: Int = 0
        if (ctrlTipoTransfusao.selectedSegmentIndex != UISegmentedControlNoSegment) {
            
            if (ctrlTipoTransfusao.selectedSegmentIndex == 0) {
                qtPlaquetasDesejadas = 100_000 // Terapêutica
            }
            else {
                qtPlaquetasDesejadas = 50_000 // Profilática
            }
            
        }
        else {
            ClearResults()
            return
        }
        
        var PlaquetometriaInt = 0
        if (countElements(txtPlaquetometria.text) > 0) {
            PlaquetometriaInt = txtPlaquetometria.text.toInt()! * 1000
        }
        else {
            ClearResults()
            return
        }
        
        let qtDiferencaPlaquetas = qtPlaquetasDesejadas - PlaquetometriaInt
        // -----------------------------------------------------------------------------------
        
        // VOLEMIA ---------------------------------------------------------------------------
         var volemia:Double = 0;
        if (ctrlTipoPaciente.selectedSegmentIndex != UISegmentedControlNoSegment) {
            
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
                    ClearResults()
                    return
                }
                
            }
            else {
                ClearResults()
                return
            }
            
            volemia = PesoDouble * Double(volemiaPorKg[ctrlTipoPaciente.selectedSegmentIndex])
        }
        else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // TIPO CONCETRADO DE PLAQUETA -------------------------------------------------------

        var kStandard:Double
        var kAferese:Double
        if (countElements(txtRendimento.text) > 0) {
            let rendimento:Double = Double(txtRendimento.text.toInt()!) / 100
            
            kStandard = 1_000_000_000 * rendimento
            kAferese  = 1_500_000_000 * rendimento
        }
        else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // APLICANDO A FÓRMULA ---------------------------------------------------------------
        let temp:Double = Double(qtDiferencaPlaquetas) * Double(volemia) * Double(1000)
        
        let finalStandard:Double = Double(temp) / Double(kStandard)
        let finalAferese:Double = Double(temp) / Double(kAferese)
        // -----------------------------------------------------------------------------------
        
        // EXIBINDO --------------------------------------------------------------------------
        var unit = NSLocalizedString("UNIT", comment: "")
        let sStandard = finalStandard / 55 >= 2 ? "s" : ""
        let sAferese = finalAferese / 200 >= 2 ? "s" : ""
        
        rsltStandard.text = NSString(format: "%.1f \(unit)\(sStandard) (%.0fml)", finalStandard / 55, finalStandard)
        rsltAferese.text = NSString(format: "%.1f \(unit)\(sAferese) (%.0fml)", finalAferese / 200, finalAferese)
        // -----------------------------------------------------------------------------------
    }
    
    // IBActions -----------------------------------------------------------------------------
    // ctrlTipoTransfusao - ValueChanged
    @IBAction func ctrlTipoTransfusao_ValueChanged(sender: UISegmentedControl)
    {
        CalculateAndShow()
    }
    
    // ctrlTipoPessoa - ValueChanged
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
    
    // ctrlUnidadePeso - ValueChanged
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
    
    // txtPeso - EditingChanged
    @IBAction func txtPeso_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }
    
    //txtRendimento - EditingChanged
    @IBAction func txtRendimento_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }
    
    //txtPlaquetometria - EditingChanged
    @IBAction func txtPlaquetometria_EditingChanged(sender: UITextField)
    {
        CalculateAndShow()
    }    
    // ---------------------------------------------------------------------------------------
}