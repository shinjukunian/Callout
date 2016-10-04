# Callout
A simple iOS message app for animated text stickers.

------------------------------
# Things I Learned
## General Architecture
The Messages Framework is suprisingly well designed and works pretty much as one would expect. The Xcode  template for a  message application, however, has a few major shortcomings: For reasons that are not entirely clear to me, the Messages App is an `message-payload-provider` extension embedded into  a wrapper application that by itself doesn't (and can't) contain any code but must contain some artwork (for the App Store, presumably).

The problem:  You can't embed frameworks into this dummy application as you normally would (the `Embedded Binaries` setting). For Debugging, one can simply add the Framework as a dependency and copy it into the message extension using a custom copy phase, but this will fail when submitting to the App Store because of nested frameworks. The workaround: https://developer.apple.com/library/content/qa/qa1936/_index.html _
Apple's description is actually quite well-done, and I more or less followed the example to the letter. The trick is to define an `External Build System` (File->New->Target->Cross-Platform), which is a simple wrapper for dependent libraries. This dummy target, which can be named ever which way, should have the frameworks one wants to embed asa dependency. The message extension by itself then depends on this target.

The trick now is to use the `Run Script`build phase of the `External Build System`to copy the framework into the `Frameworks` directory o f the hosting app (where they can be found by the message extension). Luckily, Apple provides a sample script:

    if [ "${DEPLOYMENT_LOCATION}" = "YES" ] ; then
    FRAMEWORKS_DIR="${DSTROOT}/Applications/Callout.app/Frameworks"
    else
    FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/Callout.app/Frameworks"
    fi
    rm -rf "${FRAMEWORKS_DIR}/APNG.framework"
    mkdir -p "${FRAMEWORKS_DIR}"
    cp -r "${BUILT_PRODUCTS_DIR}/APNG.framework" "${FRAMEWORKS_DIR}"
  
The subtly here is that the (absolute) path of the frameworks directory changes with build settings, hence the check for the `DEPLOYMENT_LOCATION`. Otherwise, all that is left to do is replace `Callout.app` with the app name, and `APNG.framework` with the framework name, and this should work universally. For more than one framework, I would just duplicate the `rm -rf` line (which deletes potentially previously copied frameworks) and the last `cp -r` line that does the actual copying. The (convenient?) thing is that building will fail if this is not properly set up. I did (despite the cautionary words in apples Q&A) have to mess around with codesigning. 

Things will obviously be more complicated when the embedded framework is not build in the same XCode workspace (and can't be integrated because it is vendor-supplied ). In this case (which was luckily not the case for my example App), one has to manage codesigning by oneself - I probably would just use the commandline codesign tool (following a guide like https://www.objc.io/issues/17-security/inside-code-signing/) and then use the script above instead of trying to mess with codesigning in the script.
