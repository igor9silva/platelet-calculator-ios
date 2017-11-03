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
    @IBOutlet weak var txtAltura: UITextField!
    @IBOutlet weak var txtVolume: UITextField!
    @IBOutlet weak var ctrlTipoPessoa: UISegmentedControl!
    @IBOutlet weak var ctrlUnidadePeso: UISegmentedControl!
    @IBOutlet weak var ctrlTipoBolsa: UISegmentedControl!
    @IBOutlet weak var rsltBox: UITextField!
    @IBOutlet weak var rsltCCI: UITextField!
    
    // Constants
    var txt_max_length = [2,3,3,3,4] // PlaqInicial, PlaqFinal, Peso, Altura, Volume
    
    // viewDidLoad
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Setting txtFields delegates to self, so we can apply maximum length ----------------------------------------------------
        txtPlaquetometriaInicial.delegate = self
        txtPlaquetometriaFinal.delegate = self
        txtPeso.delegate = self
        txtAltura.delegate = self
        txtVolume.delegate = self

        // ------------------------------------------------------------------------------------------------------------------------
        
        // Add 'done' button to txtFields -----------------------------------------------------------------------------------------
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneClicked))
        keyboardDoneButtonView.setItems([doneButton], animated: true)
        
        txtPlaquetometriaInicial.inputAccessoryView = keyboardDoneButtonView
        txtPlaquetometriaFinal.inputAccessoryView = keyboardDoneButtonView
        txtPeso.inputAccessoryView = keyboardDoneButtonView
        txtAltura.inputAccessoryView = keyboardDoneButtonView
        txtVolume.inputAccessoryView = keyboardDoneButtonView
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
        rsltBox.text = NSLocalizedString("MISSING_DATA", comment: "Missing some parameter, can't calculate results")
        ClearCCI()
    }
    
    func ClearCCI()
    {
        rsltCCI.text = NSLocalizedString("MISSING_DATA", comment: "Missing some parameter, can't calculate results")
    }
    
    // Calculate result and show
    func CalculateAndShow()
    {
        // DIFERENÇA DE PLAQUETAS ------------------------------------------------------------
        var qtDiferencaPlaquetas:Double = 0
        if let txt1 = txtPlaquetometriaInicial.text, !txt1.isEmpty {
            
            if let txt2 = txtPlaquetometriaFinal.text, !txt2.isEmpty,
                let val1 = Double(txt1),
                let val2 = Double(txt2) {

                qtDiferencaPlaquetas = (val2 - val1) * 1000
            } else {
                ClearResults()
                return
            }

        } else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // VOLEMIA ---------------------------------------------------------------------------
        var volemia:Double = 0;
        var PesoDouble:Double = 0

        if (ctrlTipoPessoa.selectedSegmentIndex != UISegmentedControlNoSegment) {
            
            let volemiaPorKg = [75, 65, 90, 110]
            
            if let txtPeso = txtPeso.text, !txtPeso.isEmpty {
                
                PesoDouble = Double(txtPeso) ?? 0

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
            
            volemia = PesoDouble * Double(volemiaPorKg[ctrlTipoPessoa.selectedSegmentIndex])

        } else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        // VOLUME DAS PLAQUETAS --------------------------------------------------------------
        var volume:Double = 0

        if let txt = txtVolume.text, !txt.isEmpty, let val = Double(txt) {

            if (ctrlTipoBolsa.selectedSegmentIndex != UISegmentedControlNoSegment) {

                volume = val

                // 0 = Standard | 1 = Aferese
                volume *= ctrlTipoBolsa.selectedSegmentIndex == 0 ? 1_000_000_000 : 1_500_000_000
                
            } else {
                ClearResults()
                return
            }

        } else {
            ClearResults()
            return
        }
        // -----------------------------------------------------------------------------------
        
        
        
        // APLICANDO A FÓRMULA 'RENDIMENTO' --------------------------------------------------
        let rendimento:Double = (Double(qtDiferencaPlaquetas) * volemia * 1000) / volume
        // -----------------------------------------------------------------------------------
        
        // EXIBINDO 'RENDIMENTO' -------------------------------------------------------------
        rsltBox.text = String(format: "%.0f%%", rendimento * 100)
        // -----------------------------------------------------------------------------------
        
        
        
        // ALTURA ----------------------------------------------------------------------------
        var altura:Double = 0
        if let txt = txtAltura.text, !txt.isEmpty, let val = Double(txt) {
            altura = val
        } else {
            ClearCCI()
            return
        }
        // -----------------------------------------------------------------------------------
        
        
        // APLICANDO A FÓRMULA 'CCI' ---------------------------------------------------------
        let superficie = 0.007184 * pow(altura,0.725) * pow(PesoDouble,0.425)
        let CCI:Double = (qtDiferencaPlaquetas * superficie) / (volume / 100_000_000_000)
        // -----------------------------------------------------------------------------------
        
        // EXIBINDO 'CCI' --------------------------------------------------------------------
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .decimal

        rsltCCI.text = formatter.string(from: NSNumber(value: floor(CCI)))! + "/L"
        // -----------------------------------------------------------------------------------
    }
    
    // IBActions ------------------------------------------------------------------------------------------------------------------
    @IBAction func ctrlTipoPessoa_ValueChanged(_ sender: UISegmentedControl)
    {
        if (sender.selectedSegmentIndex > 1) {

            // set maxLength for 'g'
            ctrlUnidadePeso.setTitle("g", forSegmentAt: 0)

            if (ctrlUnidadePeso.selectedSegmentIndex == 0) {
                txt_max_length[2] = 4
            }

        } else {

            // set maxLength for 'kg'
            ctrlUnidadePeso.setTitle("kg", forSegmentAt: 0)
            txt_max_length[2] = 3
            
            // If have more then maxLength caracters, delete the extra ones
            if let txt = txtPeso.text, txt.count > txt_max_length[2] {

                let end = txt.index(txt.startIndex, offsetBy: txt_max_length[2])
                txtPeso.text = String(txt[..<end])
            }
        }
        
        CalculateAndShow()
    }
    
    @IBAction func ctrlUnidadePeso_ValueChanged(_ sender: UISegmentedControl)
    {
        if (sender.selectedSegmentIndex == 0) {

            // set maxLength for 'g'
            if (sender.titleForSegment(at: 0) == "g") {
                txt_max_length[2] = 4
            }

        } else {

            // set maxLength for 'kg'
            txt_max_length[2] = 3
            
            // If have more then maxLength caracters, delete the extra ones
            if let txt = txtPeso.text, txt.count > txt_max_length[2] {

                let end = txt.index(txt.startIndex, offsetBy: txt_max_length[2])
                txtPeso.text = String(txt[..<end])
            }
        }
        
        CalculateAndShow()
    }
    
    @IBAction func ctrlTipoBolsa_ValueChanged(_ sender: UISegmentedControl)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtPlaquetometriaInicial_EditingChanged(_ sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtPlaquetometriaFinal_EditingChanged(_ sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtPeso_EditingChanged(_ sender: UITextField)
    {
        CalculateAndShow()
    }
    
    @IBAction func txtVolume_EditingChanged(_ sender: UITextField)
    {
        CalculateAndShow()
    }
    // ----------------------------------------------------------------------------------------------------------------------------
}
