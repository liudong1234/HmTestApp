import { BusinessError } from '@kit.BasicServicesKit';

// 应用/服务包含的页面
@Entry
@Component
struct Index {
  @State message: string = "hello world";

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(60)
          .fontWeight(FontWeight.Bolder)
        Image("https://th.bing.com/th/id/R.a40465e4923e78a6f6ff5decae12dbe4?rik=yMGkFld4EQIzBg&riu=http%3a%2f%2fpic.baike.soso.com%2fp%2f20140221%2f20140221010641-487941928.jpg&ehk=u%2flM4BrrMchlrRGQx3U1Y9BhaHiZ5lpx91Hp2PIyTeo%3d&risl=&pid=ImgRaw&r=0")
          .height(100)
        Divider()
        Button() {
          Text('Next')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({
          top: 5
        })
        .backgroundColor(Color.Brown)
        .width('40%')
        .height('15%')
        .onClick(() => {
          console.info(`successed in clicking  the 'next' button`)
          //获取UIContext
          let uiContext: UIContext = this.getUIContext();
          let router = uiContext.getRouter();
          //跳转第二页
          router.pushUrl({url: 'pages/Second'}).then(() => {
            console.info(`successed in jumping to the second page`)
          }).catch((err: BusinessError) => {
            console.error(`Faild to jump to the second page, ${err}`)
          })
        })
      }
      .width('100%')
    }
    .height("100%")
  }
}