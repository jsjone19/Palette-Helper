# Palette-Helper
A palette helper authored by Chaonic and J19 (Jared Jones) 

This is a script for Aseprite (see aseprite.org for more details)

I'm really grateful for Chaonic's Palette Helper Extension. It has made my life easier and my art more vibrant. I was really passionate about it the first moment I saw how beautifully it could ramp colors. The original is still an amazing piece of work and Chaonic deserves massive kudos for it.

At first, I was just tinkering with [Chaonic's Palette Helper](https://community.aseprite.org/t/extension-palette-helper/14429?u=j19) to better suit my own needs (It was a little too tall to display properly at the default UI scaling). 

However, I've added and revamped so much in the last two weeks (in which time I have not heard back from Chaonic) that I've written half of the lines of code in the current script. The only part that has remained unchanged from the original is the way the palette calculations are done. Therefore, I think it's safe to consider myself a co-author of the Palette Helper version that I am releasing here.

The UI is wider and shorter. You can resize it to be even smaller if you need to (I gave it extra space for an improved user experience).

![image|690x357](upload://7ciXDAvzncuJFQakuDQSB5gsLY8.png)

Notable functionalities that were not present in Chaonic's Palette Helper V.1.0:

* Cancel (Undo) Button
* Shades Combo Box
* Left and Right Inclusion Buttons
* Find Nearest Color Button
* Help and About Buttons
* The dialog window is free to move and doesn't snap back into place when a change is made

(The templates button is still under development)

Things I removed from the original:
* Clipboard Color
* 'Amount of Hues' and 'Amount of Soft Hues'
* Reset Button
* Reload Button

Note: The originally intended function of the cancel button was different than the mass-undo I have implemented on the button.

Under the hood, I refactored the entire code and made sure that everything was consistent.

Now you can more easily generate color ramps with the left and right inclusion buttons. You can also find the nearest color within your palette to your main color selection (at the moment this is a simple RGBA distance but in the future, I will implement a more perceptually neutral model that feels natural to humans).


