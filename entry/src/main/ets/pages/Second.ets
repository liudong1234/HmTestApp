import { BusinessError } from '@kit.BasicServicesKit';


class Person {
  name: string = '';
  names: string[] = ['a', 'b'];
  setName(name: string) {
    name = name;
  }
  getName() : string {
    return this.name;
  }
}

@Entry
@Component
struct Second {
  @State message: string = 'hi there';
  @State person: Person = new Person()

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
        Button(){
          Text('back')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({
          top: 20
        })
        .backgroundColor('yellow')
        .width('40%')
        .height('5%')
        .onClick(() => {
          console.info(`successed in clicking the 'back' button`)
              let uiContext: UIContext = this.getUIContext();
          let router = uiContext.getRouter()
          try {
            router.back()
            console.info('successed in returning to the first page')
          }
          catch (err){
            let code = (err as BusinessError).code;
            console.error(`Failed to return the first page, code is ${code}`);
          }

        })
      }
      .width('100%')
    }
    .height('100%')
  }
}