from tkinter import *
from assembler2 import *
def printText():
     
    test = textBody.get("1.0", "end-1c") 
    print(test)
    errorFlag,errorString = readLineByLine(test)
    
   
    if(not(errorFlag)):
        consoleWindow.configure(text="compiled successfully with zero errors",fg="green")
    else:
        consoleWindow.configure(text=errorString,fg="red")
    
    #print("retrun back")
def openDialogBox():
    from tkinter import filedialog
   
    root.fileName = filedialog.askopenfilename(filetypes=(("File instruction", ".txt"), ("All files","*.*")))

    print(root.fileName)         # prints filename
                                            # onto terminal
    root.title("Instruction file = "+root.fileName)  # put filename into
                                            # title bar

    #read the contents of the file
    # into the variable:  text
    # print it onto the screen for shits and giggles
    text1 = open(root.fileName).read()
    print(text1)
    textBody.delete("1.0",END)
    textBody.insert(END,text1)
        
root = Tk()
root.title('assembler')
topFrame = Frame(root)
topFrame.pack(side=TOP)
b = Button(topFrame,text="open text file",command=openDialogBox,font="Arial")
b.pack(side=LEFT)
b2 = Button(topFrame,text="generate memory file",command=printText,font="Arial")
b2.pack(side=RIGHT)
sb = Scrollbar(root)
sb.pack(side=RIGHT,fill=Y)
textBody = Text(root,font="Arial",yscrollcommand=sb.set)
textBody.pack(fill=BOTH)

consoleWindow = Label(root,text="machine instructions would be generated in instructionMemory.mem and dataMemory.mem in the same directory/folder",fg="black",font="Arial")
consoleWindow.pack(side=LEFT)
root.mainloop()





'''
root = Tk() #creating the main window
lb = Label(root,text="hey now brown cow", bg="green") #creating label
lb.pack(fill=Y,side=LEFT) #showing the label
'''
#making frames to divide your window on them
'''
topFrame = Frame(root)
topFrame.pack(side=TOP)
bottomFrame = Frame(root)
bottomFrame.pack(side=BOTTOM)

#creating button
b1 = Button(topFrame,text="click",fg="red")
b1.pack(side=LEFT)

b3 = Button(topFrame,text="click",fg="red")
b3.pack(side=RIGHT)


b2 = Button(bottomFrame,text="click here",fg="red")
b2.pack(side=LEFT,fill=X)

root.mainloop() # to make the application loops infinitly
'''