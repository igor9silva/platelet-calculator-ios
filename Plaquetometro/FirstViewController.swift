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
    var txt_max_length = [2, 3, 2] // Plaquetometria, Peso, Rendimento
    
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
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneClicked))
        keyboardDoneButtonView.setItems([doneButton], animated: true)
        
        txtPlaquetometria.inputAccessoryView = keyboardDoneButtonView
        txtRendimento.inputAccessoryView = keyboardDoneButtonView
        txtPeso.inputAccessoryView = keyboardDoneButtonView
        // ------------------------------------------------------------------------------------------------------------------------
        
        // Show "missing data"
        ClearResults()
    }
    
    // 'done' button (on numPad keyboard) pressed
    @objc func doneClicked()
    {
        // hide the keyboard
        self.view.endEditing(true)
    }
    
    // TextFields - shouldChangeCharactersInRange - applying the max length
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        // create a charset containing only numbers
        let nonNumberCharSet = CharacterSet(charactersIn: "0123456789").inverted

        // check if all 'new characters' are numbers, return false if some of them aren't
        if string.rangeOfCharacter(from: nonNumberCharSet) != nil {
            return false
        }

        let length = textField.text?.count ?? 0
        return (length + string.count - range.length < txt_max_length[textField.tag] + 1)
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
            } else {
                qtPlaquetasDesejadas = 50_000 // Profilática
            }
            
        } else {
            ClearResults()
            return
        }
        
        var PlaquetometriaInt = 0

        if let txt = txtPlaquetometria.text, !txt.isEmpty, let val = Int(txt) {
            PlaquetometriaInt = val * 1000
        } else {
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

            if let txt = txtPeso.text, !txt.isEmpty, let val = Double(txt) {
                
                PesoDouble = val

                if (ctrlUnidadePeso.selectedSegmentIndex != UISegmentedControlNoSegment) {
                    
                    if (ctrlUnidadePeso.selectedSegmentIndex == 1) { // POUNDS
                        PesoDouble = PesoDouble / 2.2
                    } else if (ctrlUnidadePeso.titleForSegment(at: 0) == "g") { // GRAMAS (not kg)
                        PesoDouble /= 1000
                    }
                    
                } else {
                    ClearResults()
                    return
                }
                
            } else {
                ClearResults()
                return
            }
            
            volemia = PesoDouble * Double(volemiaPorKg[ctrlTipoPaciente.selectedSegmentIndex])

        } else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // TIPO CONCETRADO DE PLAQUETA -------------------------------------------------------

        var kStandard:Double
        var kAferese:Double

        if let txt = txtRendimento.text, !txt.isEmpty, let val = Double(txt) {

            let rendimento:Double = val / 100
            
            kStandard = 1_000_000_000 * rendimento
            kAferese  = 1_500_000_000 * rendimento

        } else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // APLICANDO A FÓRMULA ---------------------------------------------------------------
        let temp: Double = Double(qtDiferencaPlaquetas) * Double(volemia) * Double(1000)
        
        let finalStandard:Double = Double(temp) / Double(kStandard)
        let finalAferese:Double = Double(temp) / Double(kAferese)
        // -----------------------------------------------------------------------------------
        
        // EXIBINDO --------------------------------------------------------------------------
        let unit = NSLocalizedString("UNIT", comment: "")
        let sStandard = finalStandard / 55 >= 2 ? "s" : ""
        let sAferese = finalAferese / 200 >= 2 ? "s" : ""
        
        rsltStandard.text = String(format: "%.1f \(unit)\(sStandard) (%.0fml)", finalStandard / 55, finalStandard)
        rsltAferese.text = String(format: "%.1f \(unit)\(sAferese) (%.0fml)", finalAferese / 200, finalAferese)
        // -----------------------------------------------------------------------------------
    }
    
    // IBActions -----------------------------------------------------------------------------
    // ctrlTipoTransfusao - ValueChanged
    @IBAction func ctrlTipoTransfusao_ValueChanged(_ sender: UISegmentedControl)
    {
        CalculateAndShow()
    }
    
    // ctrlTipoPessoa - ValueChanged
    @IBAction func ctrlTipoPessoa_ValueChanged(_ sender: UISegmentedControl)
    {
        if (sender.selectedSegmentIndex > 1) {

            // set maxLength for 'g'
            ctrlUnidadePeso.setTitle("g", forSegmentAt: 0)

            if (ctrlUnidadePeso.selectedSegmentIndex == 0) {
                txt_max_length[1] = 4
            }

        } else {

            // set maxLength for 'kg'
            ctrlUnidadePeso.setTitle("kg", forSegmentAt: 0)
            txt_max_length[1] = 3
            
            // If have more then maxLength caracters, delete the extra ones
            if let txt = txtPeso.text, txt.count > txt_max_length[1] {

                let end = txt.index(txt.startIndex, offsetBy: txt_max_length[1])
                txtPeso.text = String(txt[..<end])
            }
        }
        
        CalculateAndShow()
    }
    
    // ctrlUnidadePeso - ValueChanged
    @IBAction func ctrlUnidadePeso_ValueChanged(_ sender: UISegmentedControl)
    {
        if (sender.selectedSegmentIndex == 0) {

            // set maxLength for 'g'
            if (sender.titleForSegment(at: 0) == "g") {
                txt_max_length[1] = 4
            }

        } else {

            // set maxLength for 'kg'
            txt_max_length[1] = 3
            
            // If have more then maxLength caracters, delete the extra ones
            if let txt = txtPeso.text, txt.count > txt_max_length[1] {

                let end = txt.index(txt.startIndex, offsetBy: txt_max_length[1])
                txtPeso.text = String(txt[..<end])
            }
        }
        
        CalculateAndShow()
    }
    
    // txtPeso - EditingChanged
    @IBAction func txtPeso_EditingChanged(_ sender: UITextField)
    {
        CalculateAndShow()
    }
    
    //txtRendimento - EditingChanged
    @IBAction func txtRendimento_EditingChanged(_ sender: UITextField)
    {
        CalculateAndShow()
    }
    
    //txtPlaquetometria - EditingChanged
    @IBAction func txtPlaquetometria_EditingChanged(_ sender: UITextField) {
        CalculateAndShow()
    }    
    // ---------------------------------------------------------------------------------------
}
