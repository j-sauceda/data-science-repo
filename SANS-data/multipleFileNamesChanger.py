# -*- coding: utf-8 -*-

"""
Python 3 code to rename multiple Quokka .DAT files
in a directory according to their temperature, field and scan type.

Created on Wed Jan 29 19:45:18 2020

@author: Jorge Sauceda

Based on https://www.geeksforgeeks.org/rename-multiple-files-using-python/
"""


import os # imports the os module 
  
def main(): # defines how to rename multiple files 
    
    index = 0
    
    #directory = "C:/Users/z5194738/Documents/Scripts/testDir/"
    directory = "C:/Users/z5194738/UNSW/Correlated_electrons - Documentos/" + \
          "ANSTO Data/QUOKKA/20210115 COSO Light P9363/Reduced data/" + \
          "100 second setup/Field scans/54_5K FC 0-40mT/decreasingH/"
    
    namePrefix = "COSO_FC_54,5K_"
    nameSufix = "mT.DAT"
    smallSteps = 0
    
    for fileName in os.listdir(directory):
        oldName = directory + fileName
        if smallSteps == 1:
            if index >= 0 and index <= 22:
                newName = namePrefix + str(round(04.0 + 2.0*index,3)).replace(".",",") + nameSufix
            if index > 22 and index <= 24:
                newName = namePrefix + str(round(48.0 + 1.0*(index-22),3)).replace(".",",") + nameSufix
            if index > 24 and index <= 28:
                newName = namePrefix + str(round(50.0 + 0.5*(index-24),3)).replace(".",",") + nameSufix
            if index > 28 and index <= 50:
                newName = namePrefix + str(round(51.9 + 0.3*(index-28),3)).replace(".",",") + nameSufix
            if index > 50:
                newName = namePrefix + str(round(58.5 + 0.5*(index-50),3)).replace(".",",") + nameSufix
        if smallSteps == 2:
            if index >= 0 and index <= 23:
                newName = namePrefix + str(round(04.0 + 2.0*index,3)).replace(".",",") + nameSufix
            if index > 23 and index <= 27:
                newName = namePrefix + str(round(50.0 + 1.0*(index-23),3)).replace(".",",") + nameSufix
            if index > 27 and index <= 46:
                newName = namePrefix + str(round(51.9 + 0.3*(index-27),3)).replace(".",",") + nameSufix
            if index > 46:
                newName = namePrefix + str(round(58.5 + 0.5*(index-46),3)).replace(".",",") + nameSufix
        if smallSteps == 3:
            if index >= 0 and index <= 4:
                newName = namePrefix + str(round(50.0 + 1.0*(index),3)).replace(".",",") + nameSufix
            if index > 4 and index <= 19:
                newName = namePrefix + str(round(54.0 + 0.3*(index-4),3)).replace(".",",") + nameSufix
            if index > 19:
                newName = namePrefix + str(round(58.5 + 0.5*(index-19),3)).replace(".",",") + nameSufix
        if smallSteps == 4:
            if index >= 0 and index <= 15:
                newName = namePrefix + str(round(04.0 + 3.0*index,3)).replace(".",",") + nameSufix
            if index > 15 and index <= 20:
                newName = namePrefix + str(round(49.5 + 0.5*(index-15),3)).replace(".",",") + nameSufix
            if index > 20 and index <= 40:
                newName = namePrefix + str(round(52.0 + 0.3*(index-20),3)).replace(".",",") + nameSufix
            if index > 40:
                newName = namePrefix + str(round(58.0 + 1.0*(index-40),3)).replace(".",",") + nameSufix
        if smallSteps == 5:
            if index >= 0 and index <= 15:
                newName = namePrefix + str(round(04.0 + 3.0*index,3)).replace(".",",") + nameSufix
            if index > 15 and index <= 20:
                newName = namePrefix + str(round(49.5 + 0.5*(index-15),3)).replace(".",",") + nameSufix
            if index > 20 and index <= 80:
                newName = namePrefix + str(round(52.0 + 0.1*(index-20),3)).replace(".",",") + nameSufix
            if index > 80:
                newName = namePrefix + str(round(58.0 + 1.0*(index-80),3)).replace(".",",") + nameSufix
        if smallSteps == 0:
            if index >= 0:
                newName = namePrefix + str(round(39 - 1*index,2)).replace(".",",") + nameSufix
        newName = directory + newName
        os.rename(oldName, newName)
        #print(newName)
        index = index + 1

# Driver Code 
if __name__ == '__main__': 

    # Calling main() function 
    main()